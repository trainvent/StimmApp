const {ImapFlow} = require('imapflow');
const {simpleParser} = require('mailparser');
const {setTimeout: delay} = require('node:timers/promises');

async function getVerificationCode({email, password, maxAttempts = 20, delayMs = 3000}) {
  const client = new ImapFlow({
    host: 'imap.mail.de',
    port: 993,
    secure: true,
    auth: {user: email, pass: password},
    logger: false,
  });
  let connectionError;
  client.on('error', (error) => {
    connectionError = error;
  });

  try {
    await client.connect();
    const lock = await client.getMailboxLock('INBOX', {readOnly: true});
    try {
      for (let attempt = 0; attempt < maxAttempts; attempt++) {
        if (connectionError) throw connectionError;
        // Refresh the message count before checking the latest five messages.
        await client.noop();
        const count = client.mailbox.exists;
        if (count > 0) {
          const messages = await client.fetchAll(`${Math.max(1, count - 4)}:*`, {
            source: true,
          });
          // Prefer the newest matching email, rather than an older code.
          for (const message of messages.reverse()) {
            const mail = await simpleParser(message.source);
            if (!mail.subject?.includes('Your Verification Code')) continue;
            const code = (mail.text || mail.html || '').match(/\b\d{6}\b/);
            if (code) return code[0];
          }
        }
        if (attempt + 1 < maxAttempts) await delay(delayMs);
      }
      return null;
    } finally {
      lock.release();
    }
  } finally {
    try {
      if (client.usable) await client.logout();
    } finally {
      client.close();
    }
  }
}

async function main() {
  const email = process.env.TEST_HELPER_MAIL;
  const password = process.env.TEST_HELPER_SECURE_PASSWORD;
  if (!email || !password) {
    console.error('Set TEST_HELPER_MAIL and TEST_HELPER_SECURE_PASSWORD.');
    process.exitCode = 64;
    return;
  }

  try {
    const code = await getVerificationCode({email, password});
    if (code) {
      console.log(code);
    } else {
      console.error('Verification code not found.');
      process.exitCode = 1;
    }
  } catch {
    // Avoid printing server errors that could include credentials or message data.
    console.error('Unable to check verification mail. Check credentials and IMAP connectivity.');
    process.exitCode = 1;
  }
}

if (require.main === module) main();

module.exports = {getVerificationCode};
