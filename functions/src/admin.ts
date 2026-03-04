import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import * as nodemailer from "nodemailer";
import { defineSecret } from "firebase-functions/params";

// Hardcoded admin email matching IConst.adminEmail in your Dart code
const ADMIN_EMAIL = 'service@trainvent.com';
const smtpMail = process.env.SMTP_MAIL || "noreply@trainvent.com";
const smtpPassword = defineSecret('SMTP_PASSWORD');
const smtpHost = process.env.SMPT_SERVER || "smtp.ionos.de";

type ModerationAction = 'keep' | 'remove';

function buildReportResolutionUpdate(params: {
	action: 'keep' | 'remove' | 'missing';
	request: Parameters<typeof onCall>[0] extends never ? never : any;
	adminMessage: string;
}) {
	return {
		status: 'resolved',
		resolution: params.action,
		adminMessage: params.adminMessage || null,
		reviewedAt: admin.firestore.FieldValue.serverTimestamp(),
		reviewedByUid: params.request.auth!.uid,
		reviewedByEmail: params.request.auth!.token.email ?? null,
	};
}

function assertAdmin(request: Parameters<typeof onCall>[0] extends never ? never : any) {
	if (!request.auth) {
		throw new HttpsError('unauthenticated', 'The function must be called while authenticated.');
	}

	const callerEmail = request.auth.token.email;
	if (callerEmail !== ADMIN_EMAIL) {
		throw new HttpsError('permission-denied', 'Only admins can perform this action.');
	}
}

async function createTransporter() {
	const password = smtpPassword.value();
	if (!password) {
		throw new HttpsError('internal', 'Email configuration error.');
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
	} as nodemailer.TransportOptions);
}

async function sendModerationNoticeEmail(params: {
	to: string;
	contentType: string;
	contentTitle: string;
	reportId: string;
	reason: string;
	adminMessage?: string;
}) {
	const transporter = await createTransporter();
	const { to, contentType, contentTitle, reportId, reason, adminMessage } = params;
	const optionalMessage = adminMessage?.trim()
		? `\n\nZusätzliche Nachricht des Teams:\n${adminMessage.trim()}`
		: '';
	const optionalMessageHtml = adminMessage?.trim()
		? `<p><strong>Zusätzliche Nachricht des Teams:</strong><br>${adminMessage.trim().replace(/\n/g, '<br>')}</p>`
		: '';

	await transporter.sendMail({
		from: `"StimmApp Team" <${smtpMail}>`,
		to,
		subject: 'Hinweis zu gemeldetem Inhalt auf StimmApp',
		text:
			`Hallo,\n\n` +
			`dein ${contentType} "${contentTitle}" wurde nach einer Meldung durch unser Team entfernt.\n` +
			`Referenz: ${reportId}\n` +
			`Meldegrund: ${reason}\n\n` +
			`Dies gilt als Verwarnung. Bitte beachte die Community-Regeln bei zukünftigen Inhalten.` +
			optionalMessage,
		html:
			`<p>Hallo,</p>` +
			`<p>dein <strong>${contentType}</strong> "<strong>${contentTitle}</strong>" wurde nach einer Meldung durch unser Team entfernt.</p>` +
			`<p><strong>Referenz:</strong> ${reportId}<br><strong>Meldegrund:</strong> ${reason}</p>` +
			`<p>Dies gilt als Verwarnung. Bitte beachte die Community-Regeln bei zukünftigen Inhalten.</p>` +
			optionalMessageHtml,
	});
}

export const deleteUserByAdmin = onCall(async (request) => {
	assertAdmin(request);

	const uid = request.data.uid;
	if (!uid) {
		throw new HttpsError('invalid-argument', 'The function must be called with a "uid" argument.');
	}

	try {
		// 3. Delete from Authentication (this triggers onAccountDelete in user_cleanup.ts)
		await admin.auth().deleteUser(uid);

		// 4. Delete from Firestore immediately so the UI updates instantly
		await admin.firestore().collection('users').doc(uid).delete();

		return { success: true };
	} catch (error) {
		console.error("Error deleting user:", error);
		throw new HttpsError('internal', 'Unable to delete user.');
	}
});

export const moderateReport = onCall({ secrets: [smtpPassword] }, async (request) => {
	assertAdmin(request);

	const reportId = request.data.reportId as string | undefined;
	const action = request.data.action as ModerationAction | undefined;
	const adminMessage = typeof request.data.adminMessage === 'string'
		? request.data.adminMessage.trim()
		: '';

	if (!reportId || !action || !['keep', 'remove'].includes(action)) {
		throw new HttpsError('invalid-argument', 'reportId and a valid action are required.');
	}

	const db = admin.firestore();
	const reportRef = db.collection('moderationReports').doc(reportId);
	const reportSnap = await reportRef.get();
	if (!reportSnap.exists) {
		throw new HttpsError('not-found', 'Report not found.');
	}

	const report = reportSnap.data() ?? {};
	if ((report.status ?? 'open') !== 'open') {
		throw new HttpsError('failed-precondition', 'Report has already been handled.');
	}

	const contentType = report.contentType as string | undefined;
	const contentId = report.contentId as string | undefined;
	const reportedUserId = report.reportedUserId as string | undefined;
	const reason = (report.reason as string | undefined) ?? 'unknown';

	if (!contentType || !contentId || !reportedUserId) {
		throw new HttpsError('failed-precondition', 'Report is missing required moderation fields.');
	}

	if (action === 'keep') {
		await reportRef.update(
			buildReportResolutionUpdate({
				action: 'keep',
				request,
				adminMessage,
			}),
		);

		return { success: true };
	}

	const sourceCollection = contentType === 'petition' ? 'petitions' : contentType === 'poll' ? 'polls' : null;
	if (!sourceCollection) {
		throw new HttpsError('invalid-argument', `Unsupported content type: ${contentType}`);
	}

	const contentRef = db.collection(sourceCollection).doc(contentId);
	const contentSnap = await contentRef.get();
	if (!contentSnap.exists) {
		await reportRef.update({
			...buildReportResolutionUpdate({
				action: 'missing',
				request,
				adminMessage,
			}),
			contentMissingAt: admin.firestore.FieldValue.serverTimestamp(),
		});

		return {
			success: true,
			contentMissing: true,
		};
	}

	const contentData = contentSnap.data() ?? {};
	const creatorRef = db.collection('users').doc(reportedUserId);
	const creatorSnap = await creatorRef.get();
	const creatorData = creatorSnap.data() ?? {};
	const creatorEmail = creatorData.email as string | undefined;
	const contentTitle = (contentData.title as string | undefined) ?? contentId;

	await db.collection('removed').add({
		originalCollection: sourceCollection,
		originalId: contentId,
		contentType,
		contentData,
		reportId,
		reportData: report,
		removedAt: admin.firestore.FieldValue.serverTimestamp(),
		removedByUid: request.auth!.uid,
		removedByEmail: request.auth!.token.email ?? null,
		adminMessage: adminMessage || null,
	});

	await creatorRef.collection('moderationWarnings').add({
		reportId,
		contentId,
		contentType,
		reason,
		adminMessage: adminMessage || null,
		issuedAt: admin.firestore.FieldValue.serverTimestamp(),
		issuedByUid: request.auth!.uid,
		issuedByEmail: request.auth!.token.email ?? null,
		action: 'removed_content',
	});

	await reportRef.update(
		buildReportResolutionUpdate({
			action: 'remove',
			request,
			adminMessage,
		}),
	);

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
