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
exports.moderateReport = exports.deleteUserByAdmin = void 0;
const https_1 = require("firebase-functions/v2/https");
const admin = __importStar(require("firebase-admin"));
const nodemailer = __importStar(require("nodemailer"));
const params_1 = require("firebase-functions/params");
// Hardcoded admin email matching IConst.adminEmail in your Dart code
const ADMIN_EMAIL = 'service@trainvent.com';
const KICKED_USERS_COLLECTION = 'kickedUsers';
const smtpMail = process.env.SMTP_MAIL || "noreply@trainvent.com";
const smtpPassword = (0, params_1.defineSecret)('SMTP_PASSWORD');
const smtpHost = process.env.SMPT_SERVER || "smtp.strato.de";
function normalizeEmail(email) {
    return email.trim().toLowerCase();
}
function buildReportResolutionUpdate(params) {
    var _a;
    return {
        status: 'resolved',
        resolution: params.action,
        adminMessage: params.adminMessage || null,
        reviewedAt: admin.firestore.FieldValue.serverTimestamp(),
        reviewedByUid: params.request.auth.uid,
        reviewedByEmail: (_a = params.request.auth.token.email) !== null && _a !== void 0 ? _a : null,
    };
}
function assertAdmin(request) {
    if (!request.auth) {
        throw new https_1.HttpsError('unauthenticated', 'The function must be called while authenticated.');
    }
    const callerEmail = request.auth.token.email;
    if (callerEmail !== ADMIN_EMAIL) {
        throw new https_1.HttpsError('permission-denied', 'Only admins can perform this action.');
    }
}
async function createTransporter() {
    const password = smtpPassword.value();
    if (!password) {
        throw new https_1.HttpsError('internal', 'Email configuration error.');
    }
    return nodemailer.createTransport({
        host: smtpHost,
        port: 587,
        secure: false,
        requireTLS: true,
        auth: {
            user: smtpMail,
            pass: password,
        },
    });
}
async function sendModerationNoticeEmail(params) {
    const transporter = await createTransporter();
    const { to, contentType, contentTitle, reportId, reason, adminMessage } = params;
    const optionalMessage = (adminMessage === null || adminMessage === void 0 ? void 0 : adminMessage.trim())
        ? `\n\nZusätzliche Nachricht des Teams:\n${adminMessage.trim()}`
        : '';
    const optionalMessageHtml = (adminMessage === null || adminMessage === void 0 ? void 0 : adminMessage.trim())
        ? `<p><strong>Zusätzliche Nachricht des Teams:</strong><br>${adminMessage.trim().replace(/\n/g, '<br>')}</p>`
        : '';
    await transporter.sendMail({
        from: `"StimmApp Team" <${smtpMail}>`,
        to,
        subject: 'Dein StimmApp-Konto wurde entfernt',
        text: `Hallo,\n\n` +
            `dein ${contentType} "${contentTitle}" wurde nach einer Meldung durch unser Team entfernt.\n` +
            `Referenz: ${reportId}\n` +
            `Meldegrund: ${reason}\n\n` +
            `Dein StimmApp-Konto wurde aufgrund dieses Verstoßes entfernt. Eine erneute Registrierung mit dieser E-Mail-Adresse ist nicht möglich.` +
            optionalMessage,
        html: `<p>Hallo,</p>` +
            `<p>dein <strong>${contentType}</strong> "<strong>${contentTitle}</strong>" wurde nach einer Meldung durch unser Team entfernt.</p>` +
            `<p><strong>Referenz:</strong> ${reportId}<br><strong>Meldegrund:</strong> ${reason}</p>` +
            `<p>Dein StimmApp-Konto wurde aufgrund dieses Verstoßes entfernt. Eine erneute Registrierung mit dieser E-Mail-Adresse ist nicht möglich.</p>` +
            optionalMessageHtml,
    });
}
async function sendReporterResolutionEmail(params) {
    const transporter = await createTransporter();
    const { to, contentType, contentTitle, reportId, resolution, adminMessage } = params;
    const issueConfirmed = resolution === 'confirmed';
    const subject = issueConfirmed
        ? 'Deine Meldung auf StimmApp wurde bestätigt'
        : 'Update zu deiner Meldung auf StimmApp';
    const messageText = issueConfirmed
        ? `deine Meldung zu ${contentType} "${contentTitle}" wurde durch unser Team geprüft und bestätigt. Wir haben das Problem gelöst.`
        : `deine Meldung zu ${contentType} "${contentTitle}" wurde durch unser Team geprüft. Wir konnten keinen Verstoß feststellen, daher bleibt der Inhalt online.`;
    const messageHtml = issueConfirmed
        ? `deine Meldung zu <strong>${contentType}</strong> "<strong>${contentTitle}</strong>" wurde durch unser Team geprüft und bestätigt. Wir haben das Problem gelöst.`
        : `deine Meldung zu <strong>${contentType}</strong> "<strong>${contentTitle}</strong>" wurde durch unser Team geprüft. Wir konnten keinen Verstoß feststellen, daher bleibt der Inhalt online.`;
    const optionalMessage = (adminMessage === null || adminMessage === void 0 ? void 0 : adminMessage.trim())
        ? `\n\nZusätzliche Nachricht des Teams:\n${adminMessage.trim()}`
        : '';
    const optionalMessageHtml = (adminMessage === null || adminMessage === void 0 ? void 0 : adminMessage.trim())
        ? `<p><strong>Zusätzliche Nachricht des Teams:</strong><br>${adminMessage.trim().replace(/\n/g, '<br>')}</p>`
        : '';
    await transporter.sendMail({
        from: `"StimmApp Team" <${smtpMail}>`,
        to,
        subject,
        text: `Hallo,\n\n` +
            `${messageText}\n\n` +
            `Referenz: ${reportId}` +
            optionalMessage,
        html: `<p>Hallo,</p>` +
            `<p>${messageHtml}</p>` +
            `<p><strong>Referenz:</strong> ${reportId}</p>` +
            optionalMessageHtml,
    });
}
async function getReporterEmails(db, report) {
    const rawEntries = Array.isArray(report.entries) ? report.entries : [];
    const reporterIds = [
        ...new Set(rawEntries
            .map((entry) => typeof (entry === null || entry === void 0 ? void 0 : entry.reporterId) === 'string' ? entry.reporterId.trim() : '')
            .filter((reporterId) => reporterId.length > 0)),
    ];
    if (reporterIds.length === 0) {
        return [];
    }
    const userSnaps = await Promise.all(reporterIds.map((reporterId) => db.collection('users').doc(reporterId).get()));
    return userSnaps
        .map((snap) => { var _a; return (_a = snap.data()) === null || _a === void 0 ? void 0 : _a.email; })
        .filter((email) => typeof email === 'string' && email.trim().length > 0);
}
async function storeKickedUser(params) {
    var _a;
    const normalizedEmail = normalizeEmail(params.email);
    await params.db.collection(KICKED_USERS_COLLECTION).doc(normalizedEmail).set({
        email: params.email,
        normalizedEmail,
        uid: params.uid,
        reportId: params.reportId,
        contentId: params.contentId,
        contentType: params.contentType,
        reason: params.reason,
        adminMessage: params.adminMessage || null,
        kickedAt: admin.firestore.FieldValue.serverTimestamp(),
        kickedByUid: params.request.auth.uid,
        kickedByEmail: (_a = params.request.auth.token.email) !== null && _a !== void 0 ? _a : null,
    });
}
exports.deleteUserByAdmin = (0, https_1.onCall)(async (request) => {
    assertAdmin(request);
    const uid = request.data.uid;
    if (!uid) {
        throw new https_1.HttpsError('invalid-argument', 'The function must be called with a "uid" argument.');
    }
    try {
        // 3. Delete from Authentication (this triggers onAccountDelete in user_cleanup.ts)
        await admin.auth().deleteUser(uid);
        // 4. Delete from Firestore immediately so the UI updates instantly
        await admin.firestore().collection('users').doc(uid).delete();
        return { success: true };
    }
    catch (error) {
        console.error("Error deleting user:", error);
        throw new https_1.HttpsError('internal', 'Unable to delete user.');
    }
});
exports.moderateReport = (0, https_1.onCall)({ secrets: [smtpPassword] }, async (request) => {
    var _a, _b, _c, _d, _e, _f, _g, _h, _j, _k;
    assertAdmin(request);
    const reportId = request.data.reportId;
    const action = request.data.action;
    const adminMessage = typeof request.data.adminMessage === 'string'
        ? request.data.adminMessage.trim()
        : '';
    if (!reportId || !action || !['keep', 'remove'].includes(action)) {
        throw new https_1.HttpsError('invalid-argument', 'reportId and a valid action are required.');
    }
    const db = admin.firestore();
    const reportRef = db.collection('moderationReports').doc(reportId);
    const reportSnap = await reportRef.get();
    if (!reportSnap.exists) {
        throw new https_1.HttpsError('not-found', 'Report not found.');
    }
    const report = (_a = reportSnap.data()) !== null && _a !== void 0 ? _a : {};
    if (((_b = report.status) !== null && _b !== void 0 ? _b : 'open') !== 'open') {
        throw new https_1.HttpsError('failed-precondition', 'Report has already been handled.');
    }
    const contentType = report.contentType;
    const contentId = report.contentId;
    const reportedUserId = report.reportedUserId;
    const reason = (_c = report.reason) !== null && _c !== void 0 ? _c : 'unknown';
    if (!contentType || !contentId || !reportedUserId) {
        throw new https_1.HttpsError('failed-precondition', 'Report is missing required moderation fields.');
    }
    const reporterEmails = await getReporterEmails(db, report);
    const sourceCollection = contentType === 'petition' ? 'petitions' : contentType === 'poll' ? 'polls' : null;
    if (!sourceCollection) {
        throw new https_1.HttpsError('invalid-argument', `Unsupported content type: ${contentType}`);
    }
    if (action === 'keep') {
        const contentSnap = await db.collection(sourceCollection).doc(contentId).get();
        const contentTitle = (_e = (_d = contentSnap.data()) === null || _d === void 0 ? void 0 : _d.title) !== null && _e !== void 0 ? _e : contentId;
        await reportRef.update(buildReportResolutionUpdate({
            action: 'keep',
            request,
            adminMessage,
        }));
        if (reporterEmails.length > 0) {
            await Promise.all(reporterEmails.map((email) => sendReporterResolutionEmail({
                to: email,
                contentType,
                contentTitle,
                reportId,
                resolution: 'not_confirmed',
                adminMessage,
            })));
        }
        return { success: true };
    }
    const contentRef = db.collection(sourceCollection).doc(contentId);
    const contentSnap = await contentRef.get();
    if (!contentSnap.exists) {
        await reportRef.update(Object.assign(Object.assign({}, buildReportResolutionUpdate({
            action: 'missing',
            request,
            adminMessage,
        })), { contentMissingAt: admin.firestore.FieldValue.serverTimestamp() }));
        if (reporterEmails.length > 0) {
            await Promise.all(reporterEmails.map((email) => sendReporterResolutionEmail({
                to: email,
                contentType,
                contentTitle: contentId,
                reportId,
                resolution: 'confirmed',
                adminMessage,
            })));
        }
        return {
            success: true,
            contentMissing: true,
        };
    }
    const contentData = (_f = contentSnap.data()) !== null && _f !== void 0 ? _f : {};
    const creatorRef = db.collection('users').doc(reportedUserId);
    const creatorSnap = await creatorRef.get();
    const creatorData = (_g = creatorSnap.data()) !== null && _g !== void 0 ? _g : {};
    let creatorEmail = creatorData.email;
    if (!creatorEmail) {
        try {
            const creatorAuthUser = await admin.auth().getUser(reportedUserId);
            creatorEmail = creatorAuthUser.email;
        }
        catch (error) {
            console.warn(`Unable to load auth user for reported user ${reportedUserId}:`, error);
        }
    }
    const contentTitle = (_h = contentData.title) !== null && _h !== void 0 ? _h : contentId;
    await db.collection('removed').add({
        originalCollection: sourceCollection,
        originalId: contentId,
        contentType,
        contentData,
        reportId,
        reportData: report,
        removedAt: admin.firestore.FieldValue.serverTimestamp(),
        removedByUid: request.auth.uid,
        removedByEmail: (_j = request.auth.token.email) !== null && _j !== void 0 ? _j : null,
        adminMessage: adminMessage || null,
    });
    await creatorRef.collection('moderationWarnings').add({
        reportId,
        contentId,
        contentType,
        reason,
        adminMessage: adminMessage || null,
        issuedAt: admin.firestore.FieldValue.serverTimestamp(),
        issuedByUid: request.auth.uid,
        issuedByEmail: (_k = request.auth.token.email) !== null && _k !== void 0 ? _k : null,
        action: 'removed_content',
    });
    await reportRef.update(buildReportResolutionUpdate({
        action: 'remove',
        request,
        adminMessage,
    }));
    await db.recursiveDelete(contentRef);
    if (creatorEmail) {
        await sendModerationNoticeEmail({
            to: creatorEmail,
            contentType,
            contentTitle,
            reportId,
            reason,
            adminMessage,
        });
        await storeKickedUser({
            db,
            uid: reportedUserId,
            email: creatorEmail,
            reportId,
            contentId,
            contentType,
            reason,
            adminMessage,
            request,
        });
    }
    try {
        await admin.auth().deleteUser(reportedUserId);
    }
    catch (error) {
        console.error(`Failed to delete kicked user ${reportedUserId}:`, error);
        throw new https_1.HttpsError('internal', 'Content was removed, but kicking the user failed.');
    }
    if (reporterEmails.length > 0) {
        await Promise.all(reporterEmails.map((email) => sendReporterResolutionEmail({
            to: email,
            contentType,
            contentTitle,
            reportId,
            resolution: 'confirmed',
            adminMessage,
        })));
    }
    return { success: true };
});
//# sourceMappingURL=admin.js.map