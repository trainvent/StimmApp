import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from 'firebase-admin';
import * as nodemailer from 'nodemailer';

const db = admin.firestore();

// This configuration matches the successful `swaks` test.
const transporter = nodemailer.createTransport({
    host: "smtp.ionos.de",
    port: 587,
    secure: false, // Explicitly false for STARTTLS
    requireTLS: true, // Enforce STARTTLS
    auth: {
        user: "noreply@stimmapp.org",
        pass: process.env.SMTP_PASSWORD,
    },
});

// Generate a random 6-digit code
function generateCode(): string {
    return Math.floor(100000 + Math.random() * 900000).toString();
}

async function sendEmail(email: string, code: string) {
    const mailOptions = {
        from: '"StimmApp Team" <noreply@stimmapp.org>',
        to: email,
        subject: 'Your Verification Code',
        text: `Welcome to StimmApp!\n\nYour verification code is: ${code}\n\nThis code will expire in 15 minutes.`,
        html: `<p>Welcome to StimmApp!</p><p>Your verification code is: <strong>${code}</strong></p><p>This code will expire in 15 minutes.</p>`,
    };

    try {
        await transporter.sendMail(mailOptions);
        console.log(`Email sent to ${email}`);
    } catch (error) {
        console.error('Error sending email:', error);
        throw new HttpsError('internal', 'Failed to send verification email.');
    }
}

/**
 * Sends a verification code to the user's email.
 * Call this after creating the account or when requesting a new code.
 */
export const sendVerificationCode = onCall({ secrets: ["SMTP_PASSWORD"] }, async (request) => {
    if (!request.auth) {
        throw new HttpsError('unauthenticated', 'The function must be called while authenticated.');
    }

    const email = request.auth.token.email;
    if (!email) {
        throw new HttpsError('invalid-argument', 'User does not have an email address.');
    }

    const code = generateCode();
    const expirationTime = Date.now() + 15 * 60 * 1000; // 15 minutes from now

    await db.collection('verificationCodes').doc(request.auth.uid).set({
        code: code,
        email: email,
        expiresAt: expirationTime,
        attempts: 0
    });

    console.log(`[VERIFICATION] Code for ${email}: ${code}`);
    await sendEmail(email, code);

    return { success: true, message: 'Verification code sent.' };
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
    const docRef = db.collection('verificationCodes').doc(uid);
    const doc = await docRef.get();

    if (!doc.exists) {
        throw new HttpsError('not-found', 'No verification code found. Please request a new one.');
    }

    const data = doc.data();
    if (!data) return;

    if (Date.now() > data.expiresAt) {
        throw new HttpsError('deadline-exceeded', 'Verification code has expired.');
    }

    if (data.attempts >= 5) {
        await docRef.delete();
        throw new HttpsError('resource-exhausted', 'Too many failed attempts. Please request a new code.');
    }

    if (data.code !== code) {
        await docRef.update({ attempts: admin.firestore.FieldValue.increment(1) });
        throw new HttpsError('invalid-argument', 'Invalid verification code.');
    }

    await admin.auth().updateUser(uid, {
        emailVerified: true
    });

    await docRef.delete();

    return { success: true, message: 'Email verified successfully.' };
});
