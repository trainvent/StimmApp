import 'package:enough_mail/enough_mail.dart';

// Copied from IConst to avoid Flutter dependency in pure Dart script
const String testMail = "leon.marquardt@mail.de";
const String testSecurePassword = "fdsgij/3jaeflC";
const String imapServer = "imap.mail.de";

const int imapPort = 993;

void main() async {
  final client = ImapClient(isLogEnabled: true);
  try {
    print('Connecting to $imapServer...');
    await client.connectToServer(imapServer, imapPort, isSecure: true);

    print('Logging in as $testMail...');
    await client.login(testMail, testSecurePassword);
    print('Login successful!');

    print('Selecting Inbox...');
    final mailbox = await client.selectInbox();
    print('Inbox selected. Total messages: ${mailbox.messagesExists}');

    if (mailbox.messagesExists > 0) {
      print('Fetching last 5 messages...');
      final fetchResult = await client.fetchRecentMessages(
        messageCount: 5,
        criteria: 'BODY.PEEK[]',
      );

      for (final message in fetchResult.messages) {
        print('------------------------------------------------');
        print('Subject: ${message.decodeSubject()}');
        print('From: ${message.from}');
        print('Date: ${message.decodeDate()}');
      }
    } else {
      print('Inbox is empty.');
    }

    await client.logout();
  } catch (e) {
    print('Error: $e');
  }
}
