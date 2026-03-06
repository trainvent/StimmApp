#!/usr/bin/env bash
set -uo pipefail

cmd="${1:-}"
target="${2:-}"

adb_bin="${ADB_BIN:-adb}"
emulator_bin="${EMULATOR_BIN:-/home/leonmarq/Android/Sdk/emulator/emulator}"

running_serials() {
  "$adb_bin" devices 2>/dev/null | awk '/^emulator-[0-9]+\tdevice$/{print $1}' || true
}

first_running_serial() {
  running_serials | head -n1
}

serial_for_avd() {
  local avd_name="$1"
  while read -r serial; do
    local name
    name=$("$adb_bin" -s "$serial" shell getprop ro.boot.qemu.avd_name 2>/dev/null | tr -d '\r' || true)
    if [ "$name" = "$avd_name" ]; then
      echo "$serial"
      return 0
    fi
  done < <(running_serials)
  return 1
}

wait_for_boot() {
  local serial="$1"
  until [ "$("$adb_bin" -s "$serial" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r' || true)" = "1" ]; do
    sleep 1
  done
}

start_avd() {
  local avd_name="$1"
  local log_name
  log_name=$(echo "$avd_name" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-')
  setsid -f "$emulator_bin" -avd "$avd_name" >"/tmp/stimmapp-avd-${log_name}.log" 2>&1 < /dev/null
}

ensure_any() {
  local default_avd="$1"
  local serial
  "$adb_bin" start-server >/dev/null 2>&1 || true
  serial="$(first_running_serial || true)"
  if [ -z "$serial" ]; then
    start_avd "$default_avd"
    until serial="$(first_running_serial || true)"; [ -n "$serial" ]; do
      "$adb_bin" start-server >/dev/null 2>&1 || true
      sleep 1
    done
  fi
  wait_for_boot "$serial"
}

ensure_specific() {
  local avd_name="$1"
  local serial
  "$adb_bin" start-server >/dev/null 2>&1 || true
  serial="$(serial_for_avd "$avd_name" || true)"
  if [ -z "$serial" ]; then
    start_avd "$avd_name"
    until serial="$(serial_for_avd "$avd_name" || true)"; [ -n "$serial" ]; do
      "$adb_bin" start-server >/dev/null 2>&1 || true
      sleep 1
    done
  fi
  wait_for_boot "$serial"
}

case "$cmd" in
  ensure-any)
    if [ -z "$target" ]; then
      echo "Usage: $0 ensure-any <default-avd-name>" >&2
      exit 2
    fi
    ensure_any "$target"
    ;;
  ensure-specific)
    if [ -z "$target" ]; then
      echo "Usage: $0 ensure-specific <avd-name>" >&2
      exit 2
    fi
    ensure_specific "$target"
    ;;
  *)
    echo "Usage: $0 <ensure-any|ensure-specific> <avd-name>" >&2
    exit 2
    ;;
esac
