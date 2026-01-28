import 'dart:developer';

import 'package:enough_mail/enough_mail.dart';

class MailApi {
  final String _email;
  final String _password;
  final String _imapServer;
  final int _imapPort;
  final void Function(String) _logger;

  MailApi({
    required String email,
    required String password,
    String imapServer = 'imap.mail.de',
    int imapPort = 993,
    void Function(String)? logger,
  }) : _email = email,
       _password = password,
       _imapServer = imapServer,
       _imapPort = imapPort,
       _logger = logger ?? ((String msg) => log(msg));

  Future<String?> getVerificationCode({
    int maxAttempts = 20,
    Duration delay = const Duration(seconds: 3),
  }) async {
    final client = ImapClient(isLogEnabled: false);
    try {
      _logger('MailApi: Connecting to $_imapServer:$_imapPort');
      await client.connectToServer(_imapServer, _imapPort, isSecure: true);
      _logger('MailApi: Connected. Logging in...');
      await client.login(_email, _password);
      _logger('MailApi: Logged in. Selecting inbox...');
      await client.selectInbox();

      for (int i = 0; i < maxAttempts; i++) {
        _logger('MailApi: Attempt ${i + 1}/$maxAttempts. Fetching messages...');
        // Fetch the latest 5 messages to be safe
        final fetchResult = await client.fetchRecentMessages(
          messageCount: 5,
          criteria: 'BODY.PEEK[]',
        );

        for (final message in fetchResult.messages) {
          final subject = message.decodeSubject();
          _logger('MailApi: Checking message subject: $subject');

          // Check if it's the verification email
          if (subject != null && subject.contains('Your Verification Code')) {
            final body =
                message.decodeTextPlainPart() ?? message.decodeTextHtmlPart();
            if (body != null) {
              // Extract 6-digit code using Regex
              final RegExp regex = RegExp(r'\b\d{6}\b');
              final match = regex.firstMatch(body);
              if (match != null) {
                _logger('MailApi: Found code: ${match.group(0)}');
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
      _logger('MailApi Error: $e');
    } finally {
      if (client.isLoggedIn) {
        await client.logout();
      }
    }
    return null;
  }
}
