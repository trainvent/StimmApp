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
const smtpMail = process.env.SMTP_MAIL || "noreply@trainvent.com";
const smtpPassword = (0, params_1.defineSecret)('SMTP_PASSWORD');
const smtpHost = process.env.SMPT_SERVER || "smtp.ionos.de";
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
        subject: 'Hinweis zu gemeldetem Inhalt auf StimmApp',
        text: `Hallo,\n\n` +
            `dein ${contentType} "${contentTitle}" wurde nach einer Meldung durch unser Team entfernt.\n` +
            `Referenz: ${reportId}\n` +
            `Meldegrund: ${reason}\n\n` +
            `Dies gilt als Verwarnung. Bitte beachte die Community-Regeln bei zukünftigen Inhalten.` +
            optionalMessage,
        html: `<p>Hallo,</p>` +
            `<p>dein <strong>${contentType}</strong> "<strong>${contentTitle}</strong>" wurde nach einer Meldung durch unser Team entfernt.</p>` +
            `<p><strong>Referenz:</strong> ${reportId}<br><strong>Meldegrund:</strong> ${reason}</p>` +
            `<p>Dies gilt als Verwarnung. Bitte beachte die Community-Regeln bei zukünftigen Inhalten.</p>` +
            optionalMessageHtml,
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
    var _a, _b, _c, _d, _e, _f, _g, _h;
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
    if (action === 'keep') {
        await reportRef.update(buildReportResolutionUpdate({
            action: 'keep',
            request,
            adminMessage,
        }));
        return { success: true };
    }
    const sourceCollection = contentType === 'petition' ? 'petitions' : contentType === 'poll' ? 'polls' : null;
    if (!sourceCollection) {
        throw new https_1.HttpsError('invalid-argument', `Unsupported content type: ${contentType}`);
    }
    const contentRef = db.collection(sourceCollection).doc(contentId);
    const contentSnap = await contentRef.get();
    if (!contentSnap.exists) {
        await reportRef.update(Object.assign(Object.assign({}, buildReportResolutionUpdate({
            action: 'missing',
            request,
            adminMessage,
        })), { contentMissingAt: admin.firestore.FieldValue.serverTimestamp() }));
        return {
            success: true,
            contentMissing: true,
        };
    }
    const contentData = (_d = contentSnap.data()) !== null && _d !== void 0 ? _d : {};
    const creatorRef = db.collection('users').doc(reportedUserId);
    const creatorSnap = await creatorRef.get();
    const creatorData = (_e = creatorSnap.data()) !== null && _e !== void 0 ? _e : {};
    const creatorEmail = creatorData.email;
    const contentTitle = (_f = contentData.title) !== null && _f !== void 0 ? _f : contentId;
    await db.collection('removed').add({
        originalCollection: sourceCollection,
        originalId: contentId,
        contentType,
        contentData,
        reportId,
        reportData: report,
        removedAt: admin.firestore.FieldValue.serverTimestamp(),
        removedByUid: request.auth.uid,
        removedByEmail: (_g = request.auth.token.email) !== null && _g !== void 0 ? _g : null,
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
        issuedByEmail: (_h = request.auth.token.email) !== null && _h !== void 0 ? _h : null,
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
    }
    return { success: true };
});
//# sourceMappingURL=admin.js.map