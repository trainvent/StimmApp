import '../tmp/mail_api.dart';

// Copied from IConst to avoid Flutter dependency in pure Dart script
const String testMail = "leon.marquardt@mail.de";
const String testSecurePassword = "iJJmo12L_abeO";

void main() async {
  final mailApi = MailApi(
    email: testMail,
    password: testSecurePassword,
    logger: (msg) => print(msg),
  );

  print('Checking for verification code...');
  final code = await mailApi.getVerificationCode();

  if (code != null) {
    print('Verification code found: $code');
  } else {
    print('Verification code not found.');
  }
}
