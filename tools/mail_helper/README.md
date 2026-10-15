# Test mail helper

This standalone Dart package reads verification mail over IMAP. It has its own
dependency graph because enough_mail requires XML 6 while the app's PDF package
requires XML 7. No app or Patrol test imports this helper.

Run `dart pub get` in this directory before running
`dart run bin/check_verification_code.dart`. The command reads the
`TEST_HELPER_MAIL` and `TEST_HELPER_SECURE_PASSWORD` environment variables.
Keep credentials out of source control and shared logs.
