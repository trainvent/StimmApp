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
exports.updatePollGroup = exports.createPollGroup = void 0;
const https_1 = require("firebase-functions/v2/https");
const admin = __importStar(require("firebase-admin"));
const poll_group_activity_1 = require("./poll_group_activity");
const VALID_ROLES = new Set(["admin", "manager", "user"]);
const VALID_ACCESS_MODES = new Set(["private", "protected", "open"]);
const VALID_NICKNAME_MODES = new Set(["self_named", "admin_assigned"]);
function requireAuth(request) {
    var _a;
    if (!((_a = request.auth) === null || _a === void 0 ? void 0 : _a.uid)) {
        throw new https_1.HttpsError("unauthenticated", "The function must be called while authenticated.");
    }
    return request.auth.uid;
}
function asTrimmedString(value, fieldName, maxLength) {
    if (typeof value !== "string") {
        throw new https_1.HttpsError("invalid-argument", `${fieldName} must be a string.`);
    }
    const trimmed = value.trim();
    if (!trimmed) {
        throw new https_1.HttpsError("invalid-argument", `${fieldName} must not be empty.`);
    }
    if (maxLength != null && trimmed.length > maxLength) {
        throw new https_1.HttpsError("invalid-argument", `${fieldName} is too long.`);
    }
    return trimmed;
}
function normalizeEmail(value) {
    const email = asTrimmedString(value, "allowedMembers.email", 320).toLowerCase();
    if (!email.includes("@") || email.startsWith("@") || email.endsWith("@")) {
        throw new https_1.HttpsError("invalid-argument", "allowedMembers.email must be a valid email address.");
    }
    return email;
}
function normalizeDomain(value) {
    const trimmed = asTrimmedString(value, "allowedDomains.domain", 255).toLowerCase();
    const withoutAt = trimmed.startsWith("@") ? trimmed.substring(1) : trimmed;
    if (!withoutAt ||
        withoutAt.startsWith(".") ||
        withoutAt.endsWith(".") ||
        withoutAt.includes("@") ||
        !withoutAt.includes(".")) {
        throw new https_1.HttpsError("invalid-argument", "allowedDomains.domain must be a valid domain.");
    }
    return withoutAt;
}
function normalizeRole(value, fieldName) {
    if (typeof value !== "string" || !VALID_ROLES.has(value)) {
        throw new https_1.HttpsError("invalid-argument", `${fieldName} must be one of admin, manager, or user.`);
    }
    return value;
}
function normalizeOptionalString(value) {
    if (value == null) {
        return null;
    }
    if (typeof value !== "string") {
        throw new https_1.HttpsError("invalid-argument", "Optional string fields must be strings.");
    }
    const trimmed = value.trim();
    return trimmed.length === 0 ? null : trimmed;
}
function chunk(items, size) {
    const chunks = [];
    for (let index = 0; index < items.length; index += size) {
        chunks.push(items.slice(index, index + size));
    }
    return chunks;
}
exports.createPollGroup = (0, https_1.onCall)(async (request) => {
    var _a;
    const uid = requireAuth(request);
    const data = ((_a = request.data) !== null && _a !== void 0 ? _a : {});
    const db = admin.firestore();
    const now = admin.firestore.Timestamp.now();
    const name = asTrimmedString(data.name, "name", 120);
    const joinCode = asTrimmedString(data.joinCode, "joinCode", 64);
    if (typeof data.nicknameMode !== "string" || !VALID_NICKNAME_MODES.has(data.nicknameMode)) {
        throw new https_1.HttpsError("invalid-argument", "nicknameMode must be valid.");
    }
    if (typeof data.accessMode !== "string" || !VALID_ACCESS_MODES.has(data.accessMode)) {
        throw new https_1.HttpsError("invalid-argument", "accessMode must be valid.");
    }
    if (typeof data.managersCanInvite !== "boolean") {
        throw new https_1.HttpsError("invalid-argument", "managersCanInvite must be a boolean.");
    }
    if (typeof data.inviteLinkEnabled !== "boolean") {
        throw new https_1.HttpsError("invalid-argument", "inviteLinkEnabled must be a boolean.");
    }
    const creatorRef = db.collection("users").doc(uid);
    const creatorSnap = await creatorRef.get();
    const creatorData = creatorSnap.data();
    const isPro = (creatorData === null || creatorData === void 0 ? void 0 : creatorData.isPro) === true;
    const existingGroupsSnap = await db
        .collection("pollGroups")
        .where("createdBy", "==", uid)
        .limit(2)
        .get();
    if (!isPro && existingGroupsSnap.size >= 1) {
        throw new https_1.HttpsError("failed-precondition", "group_limit_requires_pro");
    }
    const expiresAtMillis = data.expiresAtMillis;
    const expiresAt = typeof expiresAtMillis === "number" && Number.isFinite(expiresAtMillis)
        ? admin.firestore.Timestamp.fromMillis(expiresAtMillis)
        : null;
    const rawAllowedMembers = Array.isArray(data.allowedMembers) ? data.allowedMembers : [];
    const rawAllowedDomains = Array.isArray(data.allowedDomains) ? data.allowedDomains : [];
    const allowedMembersByEmail = new Map();
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
    const allowedDomainsByDomain = new Map();
    for (const domain of rawAllowedDomains) {
        const normalizedDomain = normalizeDomain(domain.domain);
        allowedDomainsByDomain.set(normalizedDomain, {
            domain: normalizedDomain,
            role: normalizeRole(domain.role, "allowedDomains.role"),
            createdAt: now,
            createdBy: uid,
        });
    }
    const actorDisplayName = typeof (creatorData === null || creatorData === void 0 ? void 0 : creatorData.displayName) === "string" && creatorData.displayName.trim()
        ? creatorData.displayName.trim()
        : (typeof (creatorData === null || creatorData === void 0 ? void 0 : creatorData.email) === "string" && creatorData.email.trim()
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
    const matchingProfiles = [];
    for (const emailChunk of chunk(allowedEmails, 10)) {
        if (emailChunk.length === 0) {
            continue;
        }
        const snap = await db.collection("users").where("email", "in", emailChunk).get();
        for (const doc of snap.docs) {
            const profileData = doc.data();
            const email = typeof profileData.email === "string" ? profileData.email.trim().toLowerCase() : "";
            if (!email) {
                continue;
            }
            const displayName = typeof profileData.displayName === "string" && profileData.displayName.trim()
                ? profileData.displayName.trim()
                : null;
            matchingProfiles.push({ uid: doc.id, email, displayName });
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
        batch.set(groupRef.collection("invitations").doc(profile.uid), {
            recipientUid: profile.uid,
            email: profile.email,
            displayName: profile.displayName,
            role: allowedMember.role,
            status: "pending",
            invitedAt: now,
            invitedBy: uid,
            resolvedAt: null,
        });
    }
    (0, poll_group_activity_1.addPollGroupActivity)(batch, groupRef, {
        type: "group_created",
        actorUid: uid,
        actorDisplayName,
        createdAt: now,
    });
    if (matchingProfiles.length > 0) {
        (0, poll_group_activity_1.addPollGroupActivity)(batch, groupRef, {
            type: "invitations_sent",
            actorUid: uid,
            actorDisplayName,
            count: matchingProfiles.length,
            createdAt: now,
        });
    }
    await batch.commit();
    return { groupId: groupRef.id };
});
exports.updatePollGroup = (0, https_1.onCall)(async (request) => {
    var _a, _b, _c, _d;
    const uid = requireAuth(request);
    const data = ((_a = request.data) !== null && _a !== void 0 ? _a : {});
    const db = admin.firestore();
    const now = admin.firestore.Timestamp.now();
    const groupId = asTrimmedString(data.groupId, "groupId", 256);
    const name = asTrimmedString(data.name, "name", 120);
    if (typeof data.nicknameMode !== "string" || !VALID_NICKNAME_MODES.has(data.nicknameMode)) {
        throw new https_1.HttpsError("invalid-argument", "nicknameMode must be valid.");
    }
    if (typeof data.accessMode !== "string" || !VALID_ACCESS_MODES.has(data.accessMode)) {
        throw new https_1.HttpsError("invalid-argument", "accessMode must be valid.");
    }
    if (typeof data.managersCanInvite !== "boolean") {
        throw new https_1.HttpsError("invalid-argument", "managersCanInvite must be a boolean.");
    }
    if (typeof data.inviteLinkEnabled !== "boolean") {
        throw new https_1.HttpsError("invalid-argument", "inviteLinkEnabled must be a boolean.");
    }
    const groupRef = db.collection("pollGroups").doc(groupId);
    const [groupSnap, callerMemberSnap, callerProfileSnap] = await Promise.all([
        groupRef.get(),
        groupRef.collection("members").doc(uid).get(),
        db.collection("users").doc(uid).get(),
    ]);
    if (!groupSnap.exists) {
        throw new https_1.HttpsError("not-found", "Group not found.");
    }
    const groupData = (_b = groupSnap.data()) !== null && _b !== void 0 ? _b : {};
    const callerRole = (_c = callerMemberSnap.data()) === null || _c === void 0 ? void 0 : _c.role;
    if (groupData.createdBy !== uid && callerRole !== "admin") {
        throw new https_1.HttpsError("permission-denied", "Only group creators and admins can edit this group.");
    }
    const expiresAtMillis = data.expiresAtMillis;
    const expiresAt = typeof expiresAtMillis === "number" && Number.isFinite(expiresAtMillis)
        ? admin.firestore.Timestamp.fromMillis(expiresAtMillis)
        : null;
    const rawAllowedMembers = Array.isArray(data.allowedMembers) ? data.allowedMembers : [];
    const rawAllowedDomains = Array.isArray(data.allowedDomains) ? data.allowedDomains : [];
    const inviteEmails = Array.isArray(data.inviteEmails)
        ? new Set(data.inviteEmails.map(normalizeEmail))
        : null;
    const allowedMembersByEmail = new Map();
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
    const allowedDomainsByDomain = new Map();
    for (const domain of rawAllowedDomains) {
        const normalizedDomain = normalizeDomain(domain.domain);
        allowedDomainsByDomain.set(normalizedDomain, {
            domain: normalizedDomain,
            role: normalizeRole(domain.role, "allowedDomains.role"),
            createdAt: now,
            createdBy: uid,
        });
    }
    const [existingMemberDocs, existingDomainDocs] = await Promise.all([
        groupRef.collection("allowedMembers").get(),
        groupRef.collection("allowedDomains").get(),
    ]);
    const existingEmails = new Set(existingMemberDocs.docs.map((doc) => doc.id.toLowerCase()));
    const requestedInviteEmails = inviteEmails !== null && inviteEmails !== void 0 ? inviteEmails : new Set([...allowedMembersByEmail.keys()].filter((email) => !existingEmails.has(email)));
    const matchingProfiles = [];
    for (const emailChunk of chunk([...allowedMembersByEmail.keys()], 10)) {
        const snap = await db.collection("users").where("email", "in", emailChunk).get();
        for (const doc of snap.docs) {
            const profileData = doc.data();
            const email = typeof profileData.email === "string" ? profileData.email.trim().toLowerCase() : "";
            if (email) {
                const displayName = typeof profileData.displayName === "string" && profileData.displayName.trim()
                    ? profileData.displayName.trim()
                    : null;
                matchingProfiles.push({ uid: doc.id, email, displayName });
            }
        }
    }
    const existingInvitesByUid = new Map();
    await Promise.all(matchingProfiles.map(async (profile) => {
        const snap = await db
            .collection("users")
            .doc(profile.uid)
            .collection("groupAccessNotifications")
            .where("groupId", "==", groupId)
            .get();
        existingInvitesByUid.set(profile.uid, snap.docs
            .map((doc) => doc.data())
            .filter((notification) => notification.type === "invite"));
    }));
    const callerData = callerProfileSnap.data();
    const actorDisplayName = typeof (callerData === null || callerData === void 0 ? void 0 : callerData.displayName) === "string" && callerData.displayName.trim()
        ? callerData.displayName.trim()
        : (typeof (callerData === null || callerData === void 0 ? void 0 : callerData.email) === "string" && callerData.email.trim()
            ? callerData.email.trim()
            : "Group admin");
    const currentMemberIds = Array.isArray(groupData.memberIds) ? new Set(groupData.memberIds) : new Set();
    const batch = db.batch();
    batch.update(groupRef, {
        name,
        expiresAt,
        nicknameMode: data.nicknameMode,
        managersCanInvite: data.managersCanInvite,
        importedMemberCount: allowedMembersByEmail.size,
        accessMode: data.accessMode,
        inviteLinkEnabled: data.inviteLinkEnabled,
        nameLowercase: name.toLowerCase(),
    });
    for (const doc of existingMemberDocs.docs) {
        if (!allowedMembersByEmail.has(doc.id.toLowerCase())) {
            batch.delete(doc.ref);
        }
    }
    for (const member of allowedMembersByEmail.values()) {
        batch.set(groupRef.collection("allowedMembers").doc(member.email), member);
    }
    for (const doc of existingDomainDocs.docs) {
        if (!allowedDomainsByDomain.has(doc.id.toLowerCase())) {
            batch.delete(doc.ref);
        }
    }
    for (const domain of allowedDomainsByDomain.values()) {
        batch.set(groupRef.collection("allowedDomains").doc(domain.domain), domain);
    }
    let invitationCount = 0;
    for (const profile of matchingProfiles) {
        const allowedMember = allowedMembersByEmail.get(profile.email);
        if (!allowedMember || !requestedInviteEmails.has(profile.email) || currentMemberIds.has(profile.uid)) {
            continue;
        }
        const existingInvites = (_d = existingInvitesByUid.get(profile.uid)) !== null && _d !== void 0 ? _d : [];
        const canCreateInvite = existingInvites.every((notification) => notification.status !== "pending");
        if (!canCreateInvite) {
            continue;
        }
        const notificationRef = db
            .collection("users")
            .doc(profile.uid)
            .collection("groupAccessNotifications")
            .doc();
        batch.set(notificationRef, {
            groupId,
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
        batch.set(groupRef.collection("invitations").doc(profile.uid), {
            recipientUid: profile.uid,
            email: profile.email,
            displayName: profile.displayName,
            role: allowedMember.role,
            status: "pending",
            invitedAt: now,
            invitedBy: uid,
            resolvedAt: null,
        });
        invitationCount += 1;
    }
    const isInvitationUpdate = Array.isArray(data.inviteEmails) && data.inviteEmails.length > 0;
    if (!isInvitationUpdate) {
        (0, poll_group_activity_1.addPollGroupActivity)(batch, groupRef, {
            type: "settings_updated",
            actorUid: uid,
            actorDisplayName,
            createdAt: now,
        });
    }
    if (invitationCount > 0) {
        (0, poll_group_activity_1.addPollGroupActivity)(batch, groupRef, {
            type: "invitations_sent",
            actorUid: uid,
            actorDisplayName,
            count: invitationCount,
            createdAt: now,
        });
    }
    await batch.commit();
    return { groupId, invitationCount };
});
//# sourceMappingURL=poll_groups.js.map