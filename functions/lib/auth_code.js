"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.verifyCode = exports.sendVerificationCode = void 0;
const https_1 = require("firebase-functions/v2/https");
const admin = __importStar(require("firebase-admin"));
const nodemailer = __importStar(require("nodemailer"));
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
function generateCode() {
    return Math.floor(100000 + Math.random() * 900000).toString();
}
async function sendEmail(email, code) {
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
    }
    catch (error) {
        console.error('Error sending email:', error);
        throw new https_1.HttpsError('internal', 'Failed to send verification email.');
    }
}
/**
 * Sends a verification code to the user's email.
 * Call this after creating the account or when requesting a new code.
 */
exports.sendVerificationCode = (0, https_1.onCall)({ secrets: ["SMTP_PASSWORD"] }, async (request) => {
    if (!request.auth) {
        throw new https_1.HttpsError('unauthenticated', 'The function must be called while authenticated.');
    }
    const email = request.auth.token.email;
    if (!email) {
        throw new https_1.HttpsError('invalid-argument', 'User does not have an email address.');
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
exports.verifyCode = (0, https_1.onCall)(async (request) => {
    if (!request.auth) {
        throw new https_1.HttpsError('unauthenticated', 'The function must be called while authenticated.');
    }
    const { code } = request.data;
    if (!code) {
        throw new https_1.HttpsError('invalid-argument', 'The function must be called with a "code" argument.');
    }
    const uid = request.auth.uid;
    const email = request.auth.token.email;
    // Backdoor for testing
    if (email === 'instantKickout@protonmail.com' && code === '123456') {
        await admin.auth().updateUser(uid, {
            emailVerified: true
        });
        // Clean up any existing code doc if it exists
        await db.collection('verificationCodes').doc(uid).delete();
        return { success: true, message: 'Email verified successfully (Test Backdoor).' };
    }
    const docRef = db.collection('verificationCodes').doc(uid);
    const doc = await docRef.get();
    if (!doc.exists) {
        throw new https_1.HttpsError('not-found', 'No verification code found. Please request a new one.');
    }
    const data = doc.data();
    if (!data)
        return;
    if (Date.now() > data.expiresAt) {
        throw new https_1.HttpsError('deadline-exceeded', 'Verification code has expired.');
    }
    if (data.attempts >= 5) {
        await docRef.delete();
        throw new https_1.HttpsError('resource-exhausted', 'Too many failed attempts. Please request a new code.');
    }
    if (data.code !== code) {
        await docRef.update({ attempts: admin.firestore.FieldValue.increment(1) });
        throw new https_1.HttpsError('invalid-argument', 'Invalid verification code.');
    }
    await admin.auth().updateUser(uid, {
        emailVerified: true
    });
    await docRef.delete();
    return { success: true, message: 'Email verified successfully.' };
});
//# sourceMappingURL=auth_code.js.map