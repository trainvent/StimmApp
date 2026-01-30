// Copied from IConst to avoid Flutter dependency in pure Dart script
import 'dart:developer';

import '../mail_api.dart';

const String testMail = "leon.marquardt@mail.de";
const String testSecurePassword = "iJJmo12L_abeO";

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
