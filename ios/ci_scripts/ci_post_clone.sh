#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="${CI_PRIMARY_REPOSITORY_PATH:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

"$REPO_ROOT/ci_scripts/ci_post_clone.sh"
