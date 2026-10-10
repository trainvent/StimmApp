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
exports.getPublicProfile = exports.getParticipantResults = exports.getPublicParticipants = void 0;
exports.publicProfile = publicProfile;
exports.publicParticipant = publicParticipant;
exports.assertEvaluator = assertEvaluator;
const https_1 = require("firebase-functions/v2/https");
const admin = __importStar(require("firebase-admin"));
const targets = { petition: ["petitions", "signatures"], poll: ["polls", "votes"],
    survey: ["surveys", "responses"] };
const isAdmin = (request) => { var _a; return ((_a = request.auth) === null || _a === void 0 ? void 0 : _a.token.email) === "service@trainvent.com"; };
function id(value) {
    if (typeof value !== "string" || !value || value.includes("/") || value.length > 1500) {
        throw new https_1.HttpsError("invalid-argument", "Invalid document ID.");
    }
    return value;
}
function publicProfile(uid, profile) {
    var _a, _b;
    return { uid, displayName: (_a = profile.displayName) !== null && _a !== void 0 ? _a : null,
        profilePictureUrl: (_b = profile.profilePictureUrl) !== null && _b !== void 0 ? _b : null };
}
function publicParticipant(uid, profile, participation) {
    var _a, _b, _c;
    // Missing or malformed preferences must never reveal an identity.
    if (!profile || (profile.signAnonymously !== undefined && profile.signAnonymously !== false)) {
        return { profile: { uid: "", signAnonymously: true } };
    }
    return { profile: publicProfile(uid, profile),
        reason: typeof participation.reason === "string" ? participation.reason : null,
        signedAt: (_c = (_b = (_a = participation.signedAt) === null || _a === void 0 ? void 0 : _a.toMillis) === null || _b === void 0 ? void 0 : _b.call(_a)) !== null && _c !== void 0 ? _c : null };
}
function assertEvaluator(request, form) {
    if (!request.auth)
        throw new https_1.HttpsError("unauthenticated", "Sign in first.");
    if (!isAdmin(request) && form.createdBy !== request.auth.uid) {
        throw new https_1.HttpsError("permission-denied", "Only the creator or an administrator can export identities.");
    }
}
function encode(value) {
    if (value instanceof admin.firestore.Timestamp)
        return { timestampMillis: value.toMillis() };
    if (Array.isArray(value))
        return value.map(encode);
    if (value && typeof value === "object") {
        return Object.fromEntries(Object.entries(value).map(([key, field]) => [key, encode(field)]));
    }
    return value;
}
async function formFor(request) {
    var _a, _b, _c, _d, _e;
    const type = (_a = request.data) === null || _a === void 0 ? void 0 : _a.type;
    if (!Object.prototype.hasOwnProperty.call(targets, type)) {
        throw new https_1.HttpsError("invalid-argument", "Invalid form type.");
    }
    const [collection, participation] = targets[type];
    const ref = admin.firestore().collection(collection).doc(id((_b = request.data) === null || _b === void 0 ? void 0 : _b.formId));
    const snapshot = await ref.get();
    if (!snapshot.exists)
        throw new https_1.HttpsError("not-found", "Form not found.");
    const form = snapshot.data();
    if (form.visibility === "group" && !isAdmin(request) && form.createdBy !== ((_c = request.auth) === null || _c === void 0 ? void 0 : _c.uid)) {
        if (!request.auth || typeof form.groupId !== "string") {
            throw new https_1.HttpsError("permission-denied", "Group membership required.");
        }
        const group = await admin.firestore().collection("pollGroups").doc(form.groupId).get();
        if (!((_e = (_d = group.data()) === null || _d === void 0 ? void 0 : _d.memberIds) === null || _e === void 0 ? void 0 : _e.includes(request.auth.uid))) {
            throw new https_1.HttpsError("permission-denied", "Group membership required.");
        }
    }
    return { ref, participation, form };
}
async function participants(request, evaluator) {
    var _a, _b;
    const { ref, participation, form } = await formFor(request);
    if (evaluator)
        assertEvaluator(request, form);
    const offset = (_b = (_a = request.data) === null || _a === void 0 ? void 0 : _a.offset) !== null && _b !== void 0 ? _b : 0;
    if (!Number.isSafeInteger(offset) || offset < 0) {
        throw new https_1.HttpsError("invalid-argument", "Invalid pagination offset.");
    }
    const snapshot = await ref.collection(participation).orderBy(admin.firestore.FieldPath.documentId())
        .offset(offset).limit(200).get();
    const profiles = snapshot.empty ? [] : await admin.firestore().getAll(...snapshot.docs.map(doc => admin.firestore().collection("users").doc(doc.id)));
    const entries = snapshot.docs.map((doc, index) => evaluator ? Object.assign(Object.assign({}, encode(doc.data())), { profile: encode(Object.assign(Object.assign({}, profiles[index].data()), { uid: doc.id })) }) :
        publicParticipant(doc.id, profiles[index].data(), doc.data()));
    return { entries, nextOffset: snapshot.size === 200 ? offset + 200 : null };
}
exports.getPublicParticipants = (0, https_1.onCall)(request => participants(request, false));
exports.getParticipantResults = (0, https_1.onCall)(request => participants(request, true));
exports.getPublicProfile = (0, https_1.onCall)(async (request) => {
    var _a;
    const uid = id((_a = request.data) === null || _a === void 0 ? void 0 : _a.uid);
    const snapshot = await admin.firestore().collection("users").doc(uid).get();
    return snapshot.exists ? publicProfile(uid, snapshot.data()) : null;
});
//# sourceMappingURL=participant_privacy.js.map