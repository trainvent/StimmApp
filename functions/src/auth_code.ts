import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from 'firebase-admin';
import * as nodemailer from 'nodemailer';

const db = admin.firestore();

const smtpMail = process.env.SMTP_MAIL || "noreply@stimmapp.org";

// Generate a random 6-digit code
function generateCode(): string {
    return Math.floor(100000 + Math.random() * 900000).toString();
}

async function sendEmail(email: string, code: string, type: 'verification' | 'login') {
    const smtpPassword = process.env.SMTP_PASSWORD;
    
    console.log(`[DEBUG] Preparing to send email to ${email}. Password present: ${!!smtpPassword}`);

    if (!smtpPassword) {
        console.error("SMTP_PASSWORD is not set in environment variables.");
        throw new HttpsError('internal', 'Email configuration error.');
    }

    const transporter = nodemailer.createTransport({
        host: "smtp.ionos.de",
        port: 587,
        secure: false, // Explicitly false for STARTTLS
        requireTLS: true, // Enforce STARTTLS
        auth: {
            user: smtpMail,
            pass: smtpPassword,
        },
    });

    const subject = type === 'login' ? 'Your Login Code' : 'Your Verification Code';
    const actionText = type === 'login' ? 'log in to StimmApp' : 'verify your email';

    const mailOptions = {
        from: `"StimmApp Team" <${smtpMail}>`,
        to: email,
        subject: subject,
        text: `Welcome to StimmApp!\n\nYour code to ${actionText} is: ${code}\n\nThis code will expire in 15 minutes.`,
        html: `<p>Welcome to StimmApp!</p><p>Your code to ${actionText} is: <strong>${code}</strong></p><p>This code will expire in 15 minutes.</p>`,
    };

    try {
        await transporter.sendMail(mailOptions);
        console.log(`Email sent to ${email} (${type})`);
    } catch (error) {
        console.error('Error sending email:', error);
        throw new HttpsError('internal', `Failed to send email: ${error}`);
    }
}

async function storeCode(uid: string, email: string, type: 'verification' | 'login') {
    const code = generateCode();
    const expirationTime = Date.now() + 15 * 60 * 1000; // 15 minutes from now

    try {
        await db.collection('verificationCodes').doc(uid).set({
            code: code,
            email: email,
            expiresAt: expirationTime,
            attempts: 0,
            type: type
        });
    } catch (e) {
        console.error("Firestore write failed:", e);
        throw new HttpsError('internal', 'Database error.');
    }

    console.log(`[${type.toUpperCase()}] Code for ${email}: ${code}`);
    await sendEmail(email, code, type);
}

async function verifyCodeLogic(uid: string, code: string, email?: string) {
    console.log(`[VERIFY LOGIC] Verifying code for uid: ${uid}, email: ${email}`);
    const docRef = db.collection('verificationCodes').doc(uid);
    
    let doc;
    try {
        doc = await docRef.get();
    } catch (e) {
        console.error("Firestore read failed:", e);
        throw new HttpsError('internal', 'Database read error.');
    }

    if (!doc.exists) {
        console.warn(`No code found for uid: ${uid}`);
        throw new HttpsError('not-found', 'No code found. Please request a new one.');
    }

    const data = doc.data();
    if (!data) throw new HttpsError('not-found', 'No data found.');

    // Optional: Verify email matches if provided (crucial for login flow)
    if (email && data.email !== email) {
         console.warn(`Email mismatch. Expected: ${email}, Found: ${data.email}`);
         throw new HttpsError('invalid-argument', 'Email mismatch.');
    }

    if (Date.now() > data.expiresAt) {
        throw new HttpsError('deadline-exceeded', 'Code has expired.');
    }

    if (data.attempts >= 5) {
        await docRef.delete();
        throw new HttpsError('resource-exhausted', 'Too many failed attempts. Please request a new code.');
    }

    if (data.code !== code) {
        console.warn(`Invalid code entered for ${uid}.`);
        await docRef.update({ attempts: admin.firestore.FieldValue.increment(1) });
        throw new HttpsError('invalid-argument', 'Invalid code.');
    }

    // Code is valid. Clean up.
    await docRef.delete();
    return true;
}

/**
 * Sends a verification code to the user's email.
 * Call this after creating the account or when requesting a new code.
 */
export const sendVerificationCode = onCall(async (request) => {
    if (!request.auth) {
        throw new HttpsError('unauthenticated', 'The function must be called while authenticated.');
    }

    const email = request.auth.token.email;
    if (!email) {
        throw new HttpsError('invalid-argument', 'User does not have an email address.');
    }

    await storeCode(request.auth.uid, email, 'verification');
    return { success: true, message: 'Verification code sent.' };
});

/**
 * Sends a login code to the user's email (for passwordless login).
 * Publicly callable.
 */
export const sendLoginCode = onCall(async (request) => {
    const { email } = request.data;
    if (!email) {
        throw new HttpsError('invalid-argument', 'Email is required.');
    }

    let uid;
    try {
        const userRecord = await admin.auth().getUserByEmail(email);
        uid = userRecord.uid;
    } catch (error) {
        console.error("User lookup failed:", error);
        throw new HttpsError('not-found', 'No user found with this email.');
    }

    await storeCode(uid, email, 'login');
    return { success: true, message: 'Login code sent.' };
});

/**
 * Verifies the code entered by the user.
 * If correct, marks the email as verified in Firebase Auth.
 */
export const verifyCode = onCall(async (request) => {
    if (!request.auth) {
        throw new HttpsError('unauthenticated', 'The function must be called while authenticated.');
    }

    const { code } = request.data;
    if (!code) {
        throw new HttpsError('invalid-argument', 'The function must be called with a "code" argument.');
    }

    const uid = request.auth.uid;
    const email = request.auth.token.email;
    const isDevEnvironment = process.env.GCLOUD_PROJECT === 'stimmapp-dev';
    
    const testEmail = process.env.TEST_EMAIL;
    const testCode = process.env.TEST_CODE;

    // Backdoor for testing, ONLY in Dev environment
    if (isDevEnvironment && testEmail && testCode && email === testEmail && code === testCode) {
        await admin.auth().updateUser(uid, { emailVerified: true });
        await db.collection('verificationCodes').doc(uid).delete();
        return { success: true, message: 'Email verified successfully (Test Backdoor).' };
    }

    await verifyCodeLogic(uid, code);

    await admin.auth().updateUser(uid, {
        emailVerified: true
    });

    return { success: true, message: 'Email verified successfully.' };
});

/**
 * Verifies the login code and returns a custom auth token.
 */
export const verifyLoginCode = onCall(async (request) => {
    const { email, code } = request.data;
    if (!email || !code) {
        throw new HttpsError('invalid-argument', 'Email and code are required.');
    }

    let uid;
    try {
        const userRecord = await admin.auth().getUserByEmail(email);
        uid = userRecord.uid;
    } catch (error) {
        console.error("User lookup failed in verify:", error);
        throw new HttpsError('not-found', 'User not found.');
    }

    await verifyCodeLogic(uid, code, email);

    console.log(`[VERIFY] Code valid for ${email}. Creating custom token...`);

    // Code is valid. Generate custom token.
    let token;
    try {
        token = await admin.auth().createCustomToken(uid);
    } catch (e) {
        console.error("Error creating custom token:", e);
        throw new HttpsError('internal', 'Failed to generate login token. Check IAM permissions.');
    }

    // Also mark email as verified since they proved ownership
    try {
        await admin.auth().updateUser(uid, {
            emailVerified: true
        });
    } catch (e) {
        console.warn("Failed to update emailVerified (non-fatal):", e);
    }

    return { success: true, token: token };
});
