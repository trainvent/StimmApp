const {ImapFlow} = require('imapflow');
const {simpleParser} = require('mailparser');
const {setTimeout: delay} = require('node:timers/promises');

async function getVerificationCode({email, password, maxAttempts = 20, delayMs = 3000, logger = () => {}}) {
  const client = new ImapFlow({
    host: 'imap.gmx.net',
    port: 993,
    secure: true,
    auth: {user: email, pass: password},
    logger: false,
    connectionTimeout: 15000,
    greetingTimeout: 15000,
    socketTimeout: 15000,
  });
  let connectionError;
  client.on('error', (error) => {
    connectionError = error;
  });

  try {
    logger('Connecting to GMX and signing in...');
    await client.connect();
    logger('Signed in. Opening INBOX...');
    const lock = await client.getMailboxLock('INBOX', {readOnly: true});
    try {
      for (let attempt = 0; attempt < maxAttempts; attempt++) {
        if (connectionError) throw connectionError;
        // Refresh the message count before checking the latest five messages.
        await client.noop();
        const count = client.mailbox.exists;
        logger(`Checking latest messages (${attempt + 1}/${maxAttempts}; ${count} in INBOX)...`);
        if (count > 0) {
          const messages = await client.fetchAll(`${Math.max(1, count - 4)}:*`, {
            source: true,
          });
          // Prefer the newest matching email, rather than an older code.
          for (const message of messages.reverse()) {
            const mail = await simpleParser(message.source);
            if (!/^(Your verification code|Dein Bestätigungscode|Your login code|Dein Login-Code)$/i.test(mail.subject || '')) continue;
            const code = (mail.text || mail.html || '').match(/\b\d{6}\b/);
            if (code) return code[0];
          }
        }
        if (attempt + 1 < maxAttempts) {
          logger(`No matching code yet. Retrying in ${delayMs / 1000}s...`);
          await delay(delayMs);
        }
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
    const code = await getVerificationCode({email, password, logger: (message) => console.error(message)});
    if (code) {
      console.log(code);
    } else {
      console.error('Verification code not found.');
      process.exitCode = 1;
    }
  } catch (error) {
    // Report only known diagnostic values, never raw server responses or credentials.
    const codes = new Set([
      'ENOTFOUND', 'EAI_AGAIN', 'ECONNREFUSED', 'ECONNRESET',
      'ETIMEDOUT', 'ETIMEOUT', 'AUTHENTICATIONFAILED',
      'CERT_HAS_EXPIRED', 'UNABLE_TO_VERIFY_LEAF_SIGNATURE',
      'DEPTH_ZERO_SELF_SIGNED_CERT', 'ERR_TLS_CERT_ALTNAME_INVALID',
    ]);
    if (error.authenticationFailed) {
      console.error('GMX rejected the login. Check the app password and enable POP3/IMAP in GMX email settings.');
    } else {
      const code = codes.has(error.code) ? error.code : 'IMAP_ERROR';
      console.error(`Unable to check verification mail (${code}). Check IMAP connectivity and GMX settings.`);
    }
    process.exitCode = 1;
  }
}

if (require.main === module) main();

module.exports = {getVerificationCode};
