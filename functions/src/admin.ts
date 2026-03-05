import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import * as nodemailer from "nodemailer";
import { defineSecret } from "firebase-functions/params";
import { getBrandRuntimeConfig } from "./brand";

// Hardcoded admin email matching IConst.adminEmail in your Dart code
const ADMIN_EMAIL = 'service@trainvent.com';
const KICKED_USERS_COLLECTION = 'kickedUsers';
const smtpMail = process.env.SMTP_MAIL || "noreply@trainvent.com";
const smtpUser = process.env.SMTP_USER || smtpMail;
const smtpPassword = defineSecret('SMTP_PASSWORD');
const smtpHost = process.env.SMTP_SERVER || process.env.SMPT_SERVER || "smtp.strato.de";
const smtpPort = Number(process.env.SMTP_PORT || 465);
const smtpSecure = process.env.SMTP_SECURE
	? process.env.SMTP_SECURE === 'true'
	: smtpPort === 465;

type ModerationAction = 'keep' | 'remove';

function normalizeEmail(email: string) {
	return email.trim().toLowerCase();
}

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

type BackfillCollectionResult = {
	collection: 'petitions' | 'polls';
	scanned: number;
	updated: number;
};

async function backfillMissingCountryCode(params: {
	db: admin.firestore.Firestore;
	collection: 'petitions' | 'polls';
	countryCode: string;
	dryRun: boolean;
}): Promise<BackfillCollectionResult> {
	const { db, collection, countryCode, dryRun } = params;
	const pageSize = 500;
	const commitChunkSize = 350;

	let scanned = 0;
	let updated = 0;
	let lastDoc: admin.firestore.QueryDocumentSnapshot | null = null;
	let batch = db.batch();
	let pendingWrites = 0;

	while (true) {
		let query = db
			.collection(collection)
			.orderBy(admin.firestore.FieldPath.documentId())
			.limit(pageSize);
		if (lastDoc) {
			query = query.startAfter(lastDoc);
		}

		const snap = await query.get();
		if (snap.empty) {
			break;
		}

		for (const doc of snap.docs) {
			scanned++;
			const data = doc.data() as { countryCode?: unknown };
			const raw = data.countryCode;
			const normalized = typeof raw === 'string' ? raw.trim().toUpperCase() : '';
			const missingCountryCode = raw == null || normalized.length === 0;
			if (!missingCountryCode) {
				continue;
			}

			updated++;
			if (!dryRun) {
				batch.update(doc.ref, {
					countryCode,
					updatedAt: admin.firestore.FieldValue.serverTimestamp(),
				});
				pendingWrites++;
				if (pendingWrites >= commitChunkSize) {
					await batch.commit();
					batch = db.batch();
					pendingWrites = 0;
				}
			}
		}

		lastDoc = snap.docs[snap.docs.length - 1];
		if (snap.size < pageSize) {
			break;
		}
	}

	if (!dryRun && pendingWrites > 0) {
		await batch.commit();
	}

	return { collection, scanned, updated };
}

async function createTransporter() {
	const password = smtpPassword.value();
	if (!password) {
		throw new HttpsError('internal', 'Email configuration error.');
	}

	return nodemailer.createTransport({
		host: smtpHost,
		port: smtpPort,
		secure: smtpSecure,
		requireTLS: !smtpSecure,
		auth: {
			user: smtpUser,
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
	const brand = getBrandRuntimeConfig();
	const { to, contentType, contentTitle, reportId, reason, adminMessage } = params;
	const optionalMessage = adminMessage?.trim()
		? brand.locale === "en"
			? `\n\nAdditional message from the team:\n${adminMessage.trim()}`
			: `\n\nZusätzliche Nachricht des Teams:\n${adminMessage.trim()}`
		: '';
	const optionalMessageHtml = adminMessage?.trim()
		? brand.locale === "en"
			? `<p><strong>Additional message from the team:</strong><br>${adminMessage.trim().replace(/\n/g, '<br>')}</p>`
			: `<p><strong>Zusätzliche Nachricht des Teams:</strong><br>${adminMessage.trim().replace(/\n/g, '<br>')}</p>`
		: '';

	await transporter.sendMail({
		from: `"${brand.teamName}" <${smtpMail}>`,
		to,
		subject: brand.locale === "en"
			? `Your ${brand.appName} account was removed`
			: `Dein ${brand.appName}-Konto wurde entfernt`,
		text: brand.locale === "en"
			? `Hello,\n\n` +
			`your ${contentType} "${contentTitle}" was removed after being reviewed by our team.\n` +
			`Reference: ${reportId}\n` +
			`Reason: ${reason}\n\n` +
			`Your ${brand.appName} account was removed because of this violation. Registering again with this email address is not permitted.` +
			optionalMessage
			: `Hallo,\n\n` +
			`dein ${contentType} "${contentTitle}" wurde nach einer Meldung durch unser Team entfernt.\n` +
			`Referenz: ${reportId}\n` +
			`Meldegrund: ${reason}\n\n` +
			`Dein ${brand.appName}-Konto wurde aufgrund dieses Verstoßes entfernt. Eine erneute Registrierung mit dieser E-Mail-Adresse ist nicht möglich.` +
			optionalMessage,
		html: brand.locale === "en"
			? `<p>Hello,</p>` +
			`<p>your <strong>${contentType}</strong> "<strong>${contentTitle}</strong>" was removed after being reviewed by our team.</p>` +
			`<p><strong>Reference:</strong> ${reportId}<br><strong>Reason:</strong> ${reason}</p>` +
			`<p>Your ${brand.appName} account was removed because of this violation. Registering again with this email address is not permitted.</p>` +
			optionalMessageHtml
			: `<p>Hallo,</p>` +
			`<p>dein <strong>${contentType}</strong> "<strong>${contentTitle}</strong>" wurde nach einer Meldung durch unser Team entfernt.</p>` +
			`<p><strong>Referenz:</strong> ${reportId}<br><strong>Meldegrund:</strong> ${reason}</p>` +
			`<p>Dein ${brand.appName}-Konto wurde aufgrund dieses Verstoßes entfernt. Eine erneute Registrierung mit dieser E-Mail-Adresse ist nicht möglich.</p>` +
			optionalMessageHtml,
	});
}

async function sendReporterResolutionEmail(params: {
	to: string;
	contentType: string;
	contentTitle: string;
	reportId: string;
	resolution: 'confirmed' | 'not_confirmed';
	adminMessage?: string;
}) {
	const transporter = await createTransporter();
	const brand = getBrandRuntimeConfig();
	const { to, contentType, contentTitle, reportId, resolution, adminMessage } = params;
	const issueConfirmed = resolution === 'confirmed';
	const subject = brand.locale === "en"
		? issueConfirmed
			? `Your report on ${brand.appName} was confirmed`
			: `Update on your report on ${brand.appName}`
		: issueConfirmed
			? `Deine Meldung auf ${brand.appName} wurde bestätigt`
			: `Update zu deiner Meldung auf ${brand.appName}`;
	const messageText = brand.locale === "en"
		? issueConfirmed
			? `your report about ${contentType} "${contentTitle}" was reviewed and confirmed by our team. We resolved the issue.`
			: `your report about ${contentType} "${contentTitle}" was reviewed by our team. We could not confirm a violation, so the content remains online.`
		: issueConfirmed
			? `deine Meldung zu ${contentType} "${contentTitle}" wurde durch unser Team geprüft und bestätigt. Wir haben das Problem gelöst.`
			: `deine Meldung zu ${contentType} "${contentTitle}" wurde durch unser Team geprüft. Wir konnten keinen Verstoß feststellen, daher bleibt der Inhalt online.`;
	const messageHtml = brand.locale === "en"
		? issueConfirmed
			? `your report about <strong>${contentType}</strong> "<strong>${contentTitle}</strong>" was reviewed and confirmed by our team. We resolved the issue.`
			: `your report about <strong>${contentType}</strong> "<strong>${contentTitle}</strong>" was reviewed by our team. We could not confirm a violation, so the content remains online.`
		: issueConfirmed
			? `deine Meldung zu <strong>${contentType}</strong> "<strong>${contentTitle}</strong>" wurde durch unser Team geprüft und bestätigt. Wir haben das Problem gelöst.`
			: `deine Meldung zu <strong>${contentType}</strong> "<strong>${contentTitle}</strong>" wurde durch unser Team geprüft. Wir konnten keinen Verstoß feststellen, daher bleibt der Inhalt online.`;
	const optionalMessage = adminMessage?.trim()
		? brand.locale === "en"
			? `\n\nAdditional message from the team:\n${adminMessage.trim()}`
			: `\n\nZusätzliche Nachricht des Teams:\n${adminMessage.trim()}`
		: '';
	const optionalMessageHtml = adminMessage?.trim()
		? brand.locale === "en"
			? `<p><strong>Additional message from the team:</strong><br>${adminMessage.trim().replace(/\n/g, '<br>')}</p>`
			: `<p><strong>Zusätzliche Nachricht des Teams:</strong><br>${adminMessage.trim().replace(/\n/g, '<br>')}</p>`
		: '';

	await transporter.sendMail({
		from: `"${brand.teamName}" <${smtpMail}>`,
		to,
		subject,
		text:
			`${brand.locale === "en" ? "Hello" : "Hallo"},\n\n` +
			`${messageText}\n\n` +
			`${brand.locale === "en" ? "Reference" : "Referenz"}: ${reportId}` +
			optionalMessage,
		html:
			`<p>${brand.locale === "en" ? "Hello" : "Hallo"},</p>` +
			`<p>${messageHtml}</p>` +
			`<p><strong>${brand.locale === "en" ? "Reference" : "Referenz"}:</strong> ${reportId}</p>` +
			optionalMessageHtml,
	});
}

async function getReporterEmails(
	db: admin.firestore.Firestore,
	report: admin.firestore.DocumentData,
) {
	const rawEntries = Array.isArray(report.entries) ? report.entries : [];
	const reporterIds = [
		...new Set(
			rawEntries
				.map((entry) =>
					typeof entry?.reporterId === 'string' ? entry.reporterId.trim() : '',
				)
				.filter((reporterId) => reporterId.length > 0),
		),
	];

	if (reporterIds.length === 0) {
		return [] as string[];
	}

	const userSnaps = await Promise.all(
		reporterIds.map((reporterId) => db.collection('users').doc(reporterId).get()),
	);

	return userSnaps
		.map((snap) => snap.data()?.email)
		.filter((email): email is string => typeof email === 'string' && email.trim().length > 0);
}

async function storeKickedUser(params: {
	db: admin.firestore.Firestore;
	uid: string;
	email: string;
	removalId: string;
	reportId: string;
	contentId: string;
	contentType: string;
	reason: string;
	adminMessage: string;
	request: Parameters<typeof onCall>[0] extends never ? never : any;
}) {
	const normalizedEmail = normalizeEmail(params.email);
	await params.db.collection(KICKED_USERS_COLLECTION).doc(normalizedEmail).set({
		email: params.email,
		normalizedEmail,
		uid: params.uid,
		removalId: params.removalId,
		reportId: params.reportId,
		contentId: params.contentId,
		contentType: params.contentType,
		reason: params.reason,
		adminMessage: params.adminMessage || null,
		kickedAt: admin.firestore.FieldValue.serverTimestamp(),
		kickedByUid: params.request.auth!.uid,
		kickedByEmail: params.request.auth!.token.email ?? null,
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

export const backfillFormCountryCode = onCall(async (request) => {
	assertAdmin(request);

	const requestedCountryCode = request.data?.countryCode;
	const countryCode = typeof requestedCountryCode === 'string' && requestedCountryCode.trim().length > 0
		? requestedCountryCode.trim().toUpperCase()
		: 'DE';
	const dryRun = request.data?.dryRun !== false;

	if (countryCode.length != 2) {
		throw new HttpsError('invalid-argument', 'countryCode must be a 2-letter ISO country code.');
	}

	const db = admin.firestore();
	const [petitionsResult, pollsResult] = await Promise.all([
		backfillMissingCountryCode({
			db,
			collection: 'petitions',
			countryCode,
			dryRun,
		}),
		backfillMissingCountryCode({
			db,
			collection: 'polls',
			countryCode,
			dryRun,
		}),
	]);

	const totalScanned = petitionsResult.scanned + pollsResult.scanned;
	const totalUpdated = petitionsResult.updated + pollsResult.updated;

	return {
		success: true,
		dryRun,
		countryCode,
		totalScanned,
		totalUpdated,
		collections: [petitionsResult, pollsResult],
	};
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

	const reporterEmails = await getReporterEmails(db, report);
	const sourceCollection = contentType === 'petition' ? 'petitions' : contentType === 'poll' ? 'polls' : null;
	if (!sourceCollection) {
		throw new HttpsError('invalid-argument', `Unsupported content type: ${contentType}`);
	}

	if (action === 'keep') {
		const contentSnap = await db.collection(sourceCollection).doc(contentId).get();
		const contentTitle = (contentSnap.data()?.title as string | undefined) ?? contentId;

		await reportRef.update(
			buildReportResolutionUpdate({
				action: 'keep',
				request,
				adminMessage,
			}),
		);

		if (reporterEmails.length > 0) {
			await Promise.all(
				reporterEmails.map((email) =>
					sendReporterResolutionEmail({
						to: email,
						contentType,
						contentTitle,
						reportId,
						resolution: 'not_confirmed',
						adminMessage,
					}),
				),
			);
		}

		return { success: true };
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

		if (reporterEmails.length > 0) {
			await Promise.all(
				reporterEmails.map((email) =>
					sendReporterResolutionEmail({
						to: email,
						contentType,
						contentTitle: contentId,
						reportId,
						resolution: 'confirmed',
						adminMessage,
					}),
				),
			);
		}

		return {
			success: true,
			contentMissing: true,
		};
	}

	const contentData = contentSnap.data() ?? {};
	const creatorRef = db.collection('users').doc(reportedUserId);
	const creatorSnap = await creatorRef.get();
	const creatorData = creatorSnap.data() ?? {};
	let creatorEmail = creatorData.email as string | undefined;
	if (!creatorEmail) {
		try {
			const creatorAuthUser = await admin.auth().getUser(reportedUserId);
			creatorEmail = creatorAuthUser.email;
		} catch (error) {
			console.warn(`Unable to load auth user for reported user ${reportedUserId}:`, error);
		}
	}
	const contentTitle = (contentData.title as string | undefined) ?? contentId;

	const removalRef = await db.collection('removedForms').add({
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

		await storeKickedUser({
			db,
			uid: reportedUserId,
			email: creatorEmail,
			removalId: removalRef.id,
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
	} catch (error) {
		console.error(`Failed to delete kicked user ${reportedUserId}:`, error);
		throw new HttpsError('internal', 'Content was removed, but kicking the user failed.');
	}

	if (reporterEmails.length > 0) {
		await Promise.all(
			reporterEmails.map((email) =>
				sendReporterResolutionEmail({
					to: email,
					contentType,
					contentTitle,
					reportId,
					resolution: 'confirmed',
					adminMessage,
				}),
			),
		);
	}

	return { success: true };
});
