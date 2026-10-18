# Verification mail helper

From `functions/`, run `npm ci`, then `npm run mail:verification-code`.
Set `TEST_HELPER_MAIL` and `TEST_HELPER_SECURE_PASSWORD` in your environment first.
Keep credentials out of source control and shared logs.

The command uses ImapFlow and MailParser from the existing Node development
dependencies. It connects to `imap.mail.de:993` using TLS, opens INBOX read-only,
and checks the latest five messages up to 20 times, three seconds apart. It
extracts a six-digit code from messages whose subject contains
`Your Verification Code`, preferring newer messages. MIME text and HTML bodies
are decoded before matching. Existing messages can match, so an old verification
email can still yield an expired code.

The code is printed to stdout; treat that output as sensitive. Exit codes are
0 for a code found, 1 for no match or an IMAP error, and 64 for missing credentials.
This is a local developer command and is not exported as a Cloud Function.
