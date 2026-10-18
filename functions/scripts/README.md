# Verification mail helper

From `functions/`, run `npm ci`, then `npm run mail:verification-code`.
Set `TEST_HELPER_MAIL` and `TEST_HELPER_SECURE_PASSWORD` in the repository root
`.env` file; the npm command loads it automatically. Exported environment
variables take precedence over values in that file.
Keep credentials out of source control and shared logs.

For the current test mailbox, set `TEST_HELPER_MAIL=leon.marquardt@gmx.de`.
Use the GMX mailbox password (or an application password if required) for
`TEST_HELPER_SECURE_PASSWORD`. Enable POP3/IMAP access in GMX's email settings.

The command uses ImapFlow and MailParser from the existing Node development
dependencies. It connects to `imap.gmx.net:993` using TLS, opens INBOX read-only,
and checks the latest five messages up to 20 times, three seconds apart. It
extracts a six-digit code from messages whose subject contains
`Your verification code`, `Dein Bestätigungscode`, `Your login code`, or
`Dein Login-Code` (case-insensitive), preferring newer messages. MIME text and HTML bodies
are decoded before matching. Existing messages can match, so an old verification
email can still yield an expired code.

Progress is printed to stderr, with 15-second connection and socket inactivity
timeouts. The code is printed to stdout; treat that output as sensitive. Exit codes are
0 for a code found, 1 for no match or an IMAP error, and 64 for missing credentials.
This is a local developer command and is not exported as a Cloud Function.
