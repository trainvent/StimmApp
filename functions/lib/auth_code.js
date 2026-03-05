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
exports.assertSignupEligible = exports.verifyLoginCode = exports.verifyCode = exports.sendLoginCode = exports.sendVerificationCode = void 0;
const https_1 = require("firebase-functions/v2/https");
const admin = __importStar(require("firebase-admin"));
const nodemailer = __importStar(require("nodemailer"));
const params_1 = require("firebase-functions/params");
const brand_1 = require("./brand");
const db = admin.firestore();
const KICKED_USERS_COLLECTION = 'kickedUsers';
const smtpMail = process.env.SMTP_MAIL || "noreply@trainvent.com";
const smtpUser = process.env.SMTP_USER || smtpMail;
const smtpPassword = (0, params_1.defineSecret)('SMTP_PASSWORD');
const smtpHost = process.env.SMTP_SERVER || process.env.SMPT_SERVER || "smtp.strato.de";
const smtpPort = Number(process.env.SMTP_PORT || 465);
const smtpSecure = process.env.SMTP_SECURE
    ? process.env.SMTP_SECURE === 'true'
    : smtpPort === 465;
function normalizeEmail(email) {
    return email.trim().toLowerCase();
}
async function assertEmailNotKicked(email) {
    const normalizedEmail = normalizeEmail(email);
    const kickedUserSnap = await db.collection(KICKED_USERS_COLLECTION).doc(normalizedEmail).get();
    if (kickedUserSnap.exists) {
        const brand = (0, brand_1.getBrandRuntimeConfig)();
        throw new https_1.HttpsError('permission-denied', brand.locale === 'en'
            ? `This email address is no longer eligible to use ${brand.appName}.`
            : `Diese E-Mail-Adresse ist nicht mehr für ${brand.appName} zugelassen.`);
    }
}
// Generate a random 6-digit code
function generateCode() {
    return Math.floor(100000 + Math.random() * 900000).toString();
}
async function sendEmail(email, code, type) {
    const password = smtpPassword.value();
    const brand = (0, brand_1.getBrandRuntimeConfig)();
    console.log(`[DEBUG] Preparing to send email to ${email}. Password present: ${!!password}. Host: ${smtpHost}. User: ${smtpUser}.`);
    if (!password) {
        console.error("SMTP_PASSWORD is not set in environment variables.");
        throw new https_1.HttpsError('internal', 'Email configuration error.');
    }
    const transporter = nodemailer.createTransport({
        host: smtpHost,
        port: smtpPort,
        secure: smtpSecure,
        requireTLS: !smtpSecure,
        auth: {
            user: smtpUser,
            pass: password,
        },
    });
    const subject = brand.locale === 'en'
        ? (type === 'login' ? 'Your login code' : 'Your verification code')
        : (type === 'login' ? 'Dein Login-Code' : 'Dein Bestätigungscode');
    const actionText = brand.locale === 'en'
        ? (type === 'login'
            ? `to sign in to ${brand.appName}`
            : 'to verify your email address')
        : (type === 'login'
            ? `um dich bei ${brand.appName} anzumelden`
            : 'um deine E-Mail zu bestätigen');
    const greeting = brand.locale === 'en' ? 'Hello' : 'Hallo';
    const expiresText = brand.locale === 'en'
        ? 'This code expires in 15 minutes.'
        : 'Dieser Code läuft in 15 Minuten ab.';
    const teamName = brand.teamName;
    const mailOptions = {
        from: `"${teamName}" <${smtpMail}>`,
        to: email,
        subject: subject,
        text: brand.locale === 'en'
            ? `${greeting},\n\nYour code, ${actionText}, is: ${code}\n\n${expiresText}`
            : `${greeting},\n\nDein Code, ${actionText}, lautet: ${code}\n\n${expiresText}`,
        html: brand.locale === 'en'
            ? `<p>${greeting},</p><p>Your code, ${actionText}, is: <strong>${code}</strong></p><p>${expiresText}</p>`
            : `<p>${greeting},</p><p>Dein Code, ${actionText}, lautet: <strong>${code}</strong></p><p>${expiresText}</p>`,
    };
    try {
        await transporter.sendMail(mailOptions);
        console.log(`Email sent to ${email} (${type})`);
    }
    catch (error) {
        console.error('Error sending email:', error);
        throw new https_1.HttpsError('internal', `Failed to send email: ${error}`);
    }
}
async function storeCode(uid, email, type) {
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
    }
    catch (e) {
        console.error("Firestore write failed:", e);
        throw new https_1.HttpsError('internal', 'Database error.');
    }
    console.log(`[${type.toUpperCase()}] Code for ${email}: ${code}`);
    await sendEmail(email, code, type);
}
async function verifyCodeLogic(uid, code, email) {
    console.log(`[VERIFY LOGIC] Verifying code for uid: ${uid}, email: ${email}`);
    const docRef = db.collection('verificationCodes').doc(uid);
    let doc;
    try {
        doc = await docRef.get();
    }
    catch (e) {
        console.error("Firestore read failed:", e);
        throw new https_1.HttpsError('internal', 'Database read error.');
    }
    if (!doc.exists) {
        console.warn(`No code found for uid: ${uid}`);
        throw new https_1.HttpsError('not-found', 'No code found. Please request a new one.');
    }
    const data = doc.data();
    if (!data)
        throw new https_1.HttpsError('not-found', 'No data found.');
    // Optional: Verify email matches if provided (crucial for login flow)
    if (email && data.email !== email) {
        console.warn(`Email mismatch. Expected: ${email}, Found: ${data.email}`);
        throw new https_1.HttpsError('invalid-argument', 'Email mismatch.');
    }
    if (Date.now() > data.expiresAt) {
        throw new https_1.HttpsError('deadline-exceeded', 'Code has expired.');
    }
    if (data.attempts >= 5) {
        await docRef.delete();
        throw new https_1.HttpsError('resource-exhausted', 'Too many failed attempts. Please request a new code.');
    }
    if (data.code !== code) {
        console.warn(`Invalid code entered for ${uid}.`);
        await docRef.update({ attempts: admin.firestore.FieldValue.increment(1) });
        throw new https_1.HttpsError('invalid-argument', 'Invalid code.');
    }
    // Code is valid. Clean up.
    await docRef.delete();
    return true;
}
/**
 * Sends a verification code to the user's email.
 * Call this after creating the account or when requesting a new code.
 */
exports.sendVerificationCode = (0, https_1.onCall)({ secrets: [smtpPassword] }, async (request) => {
    if (!request.auth) {
        throw new https_1.HttpsError('unauthenticated', 'The function must be called while authenticated.');
    }
    const email = request.auth.token.email;
    if (!email) {
        throw new https_1.HttpsError('invalid-argument', 'User does not have an email address.');
    }
    await storeCode(request.auth.uid, email, 'verification');
    return { success: true, message: 'Verification code sent.' };
});
/**
 * Sends a login code to the user's email (for passwordless login).
 * Publicly callable.
 */
exports.sendLoginCode = (0, https_1.onCall)({ secrets: [smtpPassword] }, async (request) => {
    const { email } = request.data;
    if (!email) {
        throw new https_1.HttpsError('invalid-argument', 'Email is required.');
    }
    await assertEmailNotKicked(email);
    const isDevEnvironment = process.env.GCLOUD_PROJECT === 'stimmapp-dev';
    const testEmail = process.env.TEST_EMAIL;
    console.log(`[DEBUG] sendLoginCode: email='${email}'`);
    if (isDevEnvironment && testEmail) {
        const normalizedInput = email.trim().toLowerCase();
        const normalizedTest = testEmail.trim().toLowerCase();
        console.log(`[DEBUG] Checking backdoor: '${normalizedInput}' vs '${normalizedTest}'`);
        if (normalizedInput === normalizedTest) {
            console.log(`[SEND LOGIN] Test Backdoor used for ${email}. Skipping email send.`);
            return { success: true, message: 'Login code sent (Test Backdoor).' };
        }
    }
    let uid;
    try {
        const userRecord = await admin.auth().getUserByEmail(email);
        uid = userRecord.uid;
    }
    catch (error) {
        console.error("User lookup failed:", error);
        throw new https_1.HttpsError('not-found', 'No user found with this email.');
    }
    await storeCode(uid, email, 'login');
    return { success: true, message: 'Login code sent.' };
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
    const isDevEnvironment = process.env.GCLOUD_PROJECT === 'stimmapp-dev';
    const testEmail = process.env.TEST_EMAIL;
    const testCode = process.env.TEST_CODE;
    // Backdoor for testing, ONLY in Dev environment
    if (isDevEnvironment && testEmail && testCode && email) {
        const normalizedInput = email.trim().toLowerCase();
        const normalizedTest = testEmail.trim().toLowerCase();
        if (normalizedInput === normalizedTest && code === testCode) {
            await admin.auth().updateUser(uid, { emailVerified: true });
            await db.collection('verificationCodes').doc(uid).delete();
            return { success: true, message: 'Email verified successfully (Test Backdoor).' };
        }
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
exports.verifyLoginCode = (0, https_1.onCall)(async (request) => {
    const { email, code } = request.data;
    if (!email || !code) {
        throw new https_1.HttpsError('invalid-argument', 'Email and code are required.');
    }
    await assertEmailNotKicked(email);
    let uid;
    try {
        const userRecord = await admin.auth().getUserByEmail(email);
        uid = userRecord.uid;
    }
    catch (error) {
        console.error("User lookup failed in verify:", error);
        throw new https_1.HttpsError('not-found', 'User not found.');
    }
    const isDevEnvironment = process.env.GCLOUD_PROJECT === 'stimmapp-dev';
    const testEmail = process.env.TEST_EMAIL;
    const testCode = process.env.TEST_CODE;
    console.log(`[DEBUG] verifyLoginCode: email='${email}', code='${code}'`);
    let isBackdoor = false;
    if (isDevEnvironment && testEmail && testCode) {
        const normalizedInput = email.trim().toLowerCase();
        const normalizedTest = testEmail.trim().toLowerCase();
        console.log(`[DEBUG] Checking backdoor: '${normalizedInput}' vs '${normalizedTest}'`);
        if (normalizedInput === normalizedTest && code === testCode) {
            isBackdoor = true;
        }
    }
    // Backdoor for testing, ONLY in Dev environment
    if (isBackdoor) {
        console.log(`[VERIFY] Test Backdoor used for ${email}. Creating custom token...`);
        // Skip verifyCodeLogic and proceed to token creation
    }
    else {
        await verifyCodeLogic(uid, code, email);
    }
    console.log(`[VERIFY] Code valid for ${email}. Creating custom token...`);
    // Code is valid. Generate custom token.
    let token;
    try {
        token = await admin.auth().createCustomToken(uid);
    }
    catch (e) {
        console.error("Error creating custom token:", e);
        // Check for the specific IAM permission error
        if (e.code === 'auth/insufficient-permission' || (e.message && e.message.includes('iam.serviceAccounts.signBlob'))) {
            throw new https_1.HttpsError('internal', 'Server configuration error: Missing IAM permissions for token creation. Please contact support.');
        }
        throw new https_1.HttpsError('internal', 'Failed to generate login token.');
    }
    // Also mark email as verified since they proved ownership
    try {
        await admin.auth().updateUser(uid, {
            emailVerified: true
        });
    }
    catch (e) {
        console.warn("Failed to update emailVerified (non-fatal):", e);
    }
    return { success: true, token: token };
});
exports.assertSignupEligible = (0, https_1.onCall)(async (request) => {
    const email = request.data.email;
    if (!email) {
        throw new https_1.HttpsError('invalid-argument', 'Email is required.');
    }
    await assertEmailNotKicked(email);
    return { success: true };
});
//# sourceMappingURL=auth_code.js.map