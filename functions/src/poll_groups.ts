import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

type CreatePollGroupPayload = {
	name?: unknown;
	joinCode?: unknown;
	nicknameMode?: unknown;
	managersCanInvite?: unknown;
	accessMode?: unknown;
	inviteLinkEnabled?: unknown;
	expiresAtMillis?: unknown;
	allowedMembers?: unknown;
	allowedDomains?: unknown;
};

type AllowedMemberInput = {
	email?: unknown;
	nickname?: unknown;
	role?: unknown;
};

type AllowedDomainInput = {
	domain?: unknown;
	role?: unknown;
};

const VALID_ROLES = new Set(["admin", "manager", "user"]);
const VALID_ACCESS_MODES = new Set(["private", "protected", "open"]);
const VALID_NICKNAME_MODES = new Set(["self_named", "admin_assigned"]);

function requireAuth(request: Parameters<typeof onCall>[0] extends never ? never : any) {
	if (!request.auth?.uid) {
		throw new HttpsError("unauthenticated", "The function must be called while authenticated.");
	}
	return request.auth.uid as string;
}

function asTrimmedString(value: unknown, fieldName: string, maxLength?: number) {
	if (typeof value !== "string") {
		throw new HttpsError("invalid-argument", `${fieldName} must be a string.`);
	}
	const trimmed = value.trim();
	if (!trimmed) {
		throw new HttpsError("invalid-argument", `${fieldName} must not be empty.`);
	}
	if (maxLength != null && trimmed.length > maxLength) {
		throw new HttpsError("invalid-argument", `${fieldName} is too long.`);
	}
	return trimmed;
}

function normalizeEmail(value: unknown) {
	const email = asTrimmedString(value, "allowedMembers.email", 320).toLowerCase();
	if (!email.includes("@") || email.startsWith("@") || email.endsWith("@")) {
		throw new HttpsError("invalid-argument", "allowedMembers.email must be a valid email address.");
	}
	return email;
}

function normalizeDomain(value: unknown) {
	const trimmed = asTrimmedString(value, "allowedDomains.domain", 255).toLowerCase();
	const withoutAt = trimmed.startsWith("@") ? trimmed.substring(1) : trimmed;
	if (
		!withoutAt ||
		withoutAt.startsWith(".") ||
		withoutAt.endsWith(".") ||
		withoutAt.includes("@") ||
		!withoutAt.includes(".")
	) {
		throw new HttpsError("invalid-argument", "allowedDomains.domain must be a valid domain.");
	}
	return withoutAt;
}

function normalizeRole(value: unknown, fieldName: string) {
	if (typeof value !== "string" || !VALID_ROLES.has(value)) {
		throw new HttpsError("invalid-argument", `${fieldName} must be one of admin, manager, or user.`);
	}
	return value;
}

function normalizeOptionalString(value: unknown) {
	if (value == null) {
		return null;
	}
	if (typeof value !== "string") {
		throw new HttpsError("invalid-argument", "Optional string fields must be strings.");
	}
	const trimmed = value.trim();
	return trimmed.length === 0 ? null : trimmed;
}

function chunk<T>(items: T[], size: number) {
	const chunks: T[][] = [];
	for (let index = 0; index < items.length; index += size) {
		chunks.push(items.slice(index, index + size));
	}
	return chunks;
}

export const createPollGroup = onCall(async (request) => {
	const uid = requireAuth(request);
	const data = (request.data ?? {}) as CreatePollGroupPayload;
	const db = admin.firestore();
	const now = admin.firestore.Timestamp.now();

	const name = asTrimmedString(data.name, "name", 120);
	const joinCode = asTrimmedString(data.joinCode, "joinCode", 64);

	if (typeof data.nicknameMode !== "string" || !VALID_NICKNAME_MODES.has(data.nicknameMode)) {
		throw new HttpsError("invalid-argument", "nicknameMode must be valid.");
	}
	if (typeof data.accessMode !== "string" || !VALID_ACCESS_MODES.has(data.accessMode)) {
		throw new HttpsError("invalid-argument", "accessMode must be valid.");
	}
	if (typeof data.managersCanInvite !== "boolean") {
		throw new HttpsError("invalid-argument", "managersCanInvite must be a boolean.");
	}
	if (typeof data.inviteLinkEnabled !== "boolean") {
		throw new HttpsError("invalid-argument", "inviteLinkEnabled must be a boolean.");
	}

	const creatorRef = db.collection("users").doc(uid);
	const creatorSnap = await creatorRef.get();
	const creatorData = creatorSnap.data() as { isPro?: unknown; displayName?: unknown; email?: unknown } | undefined;
	const isPro = creatorData?.isPro === true;

	const existingGroupsSnap = await db
		.collection("pollGroups")
		.where("createdBy", "==", uid)
		.limit(2)
		.get();
	if (!isPro && existingGroupsSnap.size >= 1) {
		throw new HttpsError("failed-precondition", "group_limit_requires_pro");
	}

	const expiresAtMillis = data.expiresAtMillis;
	const expiresAt = typeof expiresAtMillis === "number" && Number.isFinite(expiresAtMillis)
		? admin.firestore.Timestamp.fromMillis(expiresAtMillis)
		: null;

	const rawAllowedMembers = Array.isArray(data.allowedMembers) ? data.allowedMembers as AllowedMemberInput[] : [];
	const rawAllowedDomains = Array.isArray(data.allowedDomains) ? data.allowedDomains as AllowedDomainInput[] : [];

	const allowedMembersByEmail = new Map<string, {
		email: string;
		nickname: string | null;
		role: string;
		createdAt: admin.firestore.Timestamp;
		createdBy: string;
		emailLowercase: string;
	}>();
	for (const member of rawAllowedMembers) {
		const email = normalizeEmail(member.email);
		allowedMembersByEmail.set(email, {
			email,
			emailLowercase: email,
			nickname: normalizeOptionalString(member.nickname),
			role: normalizeRole(member.role, "allowedMembers.role"),
			createdAt: now,
			createdBy: uid,
		});
	}

	const allowedDomainsByDomain = new Map<string, {
		domain: string;
		role: string;
		createdAt: admin.firestore.Timestamp;
		createdBy: string;
	}>();
	for (const domain of rawAllowedDomains) {
		const normalizedDomain = normalizeDomain(domain.domain);
		allowedDomainsByDomain.set(normalizedDomain, {
			domain: normalizedDomain,
			role: normalizeRole(domain.role, "allowedDomains.role"),
			createdAt: now,
			createdBy: uid,
		});
	}

	const actorDisplayName =
		typeof creatorData?.displayName === "string" && creatorData.displayName.trim()
			? creatorData.displayName.trim()
			: (typeof creatorData?.email === "string" && creatorData.email.trim()
				? creatorData.email.trim()
				: "Group admin");

	const groupRef = db.collection("pollGroups").doc();
	const batch = db.batch();

	batch.set(groupRef, {
		name,
		createdBy: uid,
		createdAt: now,
		expiresAt,
		joinCode,
		nicknameMode: data.nicknameMode,
		managersCanInvite: data.managersCanInvite,
		memberIds: [uid],
		importedMemberCount: allowedMembersByEmail.size,
		isActive: true,
		accessMode: data.accessMode,
		inviteLinkEnabled: data.inviteLinkEnabled,
		nameLowercase: name.toLowerCase(),
	});

	batch.set(groupRef.collection("members").doc(uid), {
		role: "admin",
		nickname: null,
		joinedAt: now,
		joinedBy: uid,
	});

	for (const member of allowedMembersByEmail.values()) {
		batch.set(groupRef.collection("allowedMembers").doc(member.email), member);
	}
	for (const domain of allowedDomainsByDomain.values()) {
		batch.set(groupRef.collection("allowedDomains").doc(domain.domain), domain);
	}

	const allowedEmails = [...allowedMembersByEmail.keys()];
	const matchingProfiles: Array<{ uid: string; email: string }> = [];
	for (const emailChunk of chunk(allowedEmails, 10)) {
		if (emailChunk.length === 0) {
			continue;
		}
		const snap = await db.collection("users").where("email", "in", emailChunk).get();
		for (const doc of snap.docs) {
			const email = typeof doc.data().email === "string" ? doc.data().email.trim().toLowerCase() : "";
			if (!email) {
				continue;
			}
			matchingProfiles.push({ uid: doc.id, email });
		}
	}

	for (const profile of matchingProfiles) {
		const allowedMember = allowedMembersByEmail.get(profile.email);
		if (!allowedMember) {
			continue;
		}
		const notificationRef = db
			.collection("users")
			.doc(profile.uid)
			.collection("groupAccessNotifications")
			.doc();
		batch.set(notificationRef, {
			groupId: groupRef.id,
			groupName: name,
			actorUid: uid,
			actorDisplayName,
			recipientUid: profile.uid,
			role: allowedMember.role,
			accessMode: data.accessMode,
			type: "invite",
			status: "pending",
			createdAt: now,
			resolvedAt: null,
		});
	}

	await batch.commit();

	return { groupId: groupRef.id };
});
