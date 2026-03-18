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
exports.createPollGroup = void 0;
const https_1 = require("firebase-functions/v2/https");
const admin = __importStar(require("firebase-admin"));
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
//# sourceMappingURL=poll_groups.js.map