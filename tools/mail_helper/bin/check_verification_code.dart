import 'dart:developer';
import 'dart:io';

import 'package:stimmapp_mail_helper/mail_api.dart';

void main() async {
  final testMail = Platform.environment['TEST_HELPER_MAIL'] ?? '';
  final testSecurePassword =
      Platform.environment['TEST_HELPER_SECURE_PASSWORD'] ?? '';
  if (testMail.isEmpty || testSecurePassword.isEmpty) {
    stderr.writeln('Set TEST_HELPER_MAIL and TEST_HELPER_SECURE_PASSWORD.');
    exitCode = 64;
    return;
  }
  final mailApi = MailApi(
    email: testMail,
    password: testSecurePassword,
    logger: (msg) => log(msg),
  );

  log('Checking for verification code...');
  final code = await mailApi.getVerificationCode();

  if (code != null) {
    log('Verification code found: $code');
  } else {
    log('Verification code not found.');
  }
}
