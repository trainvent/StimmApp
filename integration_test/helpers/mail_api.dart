import 'package:enough_mail/enough_mail.dart';

class MailApi {
  final String _email;
  final String _password;
  final String _imapServer;
  final int _imapPort;

  MailApi({
    required String email,
    required String password,
    String imapServer = 'imap.ionos.de',
    int imapPort = 993,
  }) : _email = email,
       _password = password,
       _imapServer = imapServer,
       _imapPort = imapPort;

  Future<String?> getVerificationCode({
    int maxAttempts = 10,
    Duration delay = const Duration(seconds: 2),
  }) async {
    final client = ImapClient(isLogEnabled: false);
    try {
      await client.connectToServer(_imapServer, _imapPort, isSecure: true);
      await client.login(_email, _password);
      await client.selectInbox();

      for (int i = 0; i < maxAttempts; i++) {
        // Fetch the latest message
        final fetchResult = await client.fetchRecentMessages(
          messageCount: 1,
          criteria: 'BODY.PEEK[]',
        );

        if (fetchResult.messages.isNotEmpty) {
          final message = fetchResult.messages.first;
          final subject = message.decodeSubject();

          // Check if it's the verification email
          if (subject != null && subject.contains('Your Verification Code')) {
            final body =
                message.decodeTextPlainPart() ?? message.decodeTextHtmlPart();
            if (body != null) {
              // Extract 6-digit code using Regex
              final RegExp regex = RegExp(r'\b\d{6}\b');
              final match = regex.firstMatch(body);
              if (match != null) {
                await client.logout();
                return match.group(0);
              }
            }
          }
        }

        // Wait before retrying
        await Future.delayed(delay);
      }
    } catch (e) {
      print('MailApi Error: $e');
    } finally {
      if (client.isLoggedIn) {
        await client.logout();
      }
    }
    return null;
  }
}
