import 'dart:developer';

import '../mail_api.dart';

const String testMail = String.fromEnvironment(
  'TEST_HELPER_MAIL',
  defaultValue: '',
);
const String testSecurePassword = String.fromEnvironment(
  'TEST_HELPER_SECURE_PASSWORD',
  defaultValue: '',
);

void main() async {
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
