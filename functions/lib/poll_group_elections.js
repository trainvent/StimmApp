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
exports.finalizePollGroupAdminElections = exports.castPollGroupAdminVote = exports.leavePollGroup = void 0;
exports.handlePollGroupMemberDeparture = handlePollGroupMemberDeparture;
exports.handleUserPollGroupDepartures = handleUserPollGroupDepartures;
const https_1 = require("firebase-functions/v2/https");
const scheduler_1 = require("firebase-functions/v2/scheduler");
const admin = __importStar(require("firebase-admin"));
const poll_group_activity_1 = require("./poll_group_activity");
const ELECTION_DURATION_MS = 3 * 24 * 60 * 60 * 1000;
async function clearElectionVotes(db, groupRef) {
    const votes = await groupRef
        .collection("adminElections")
        .doc("current")
        .collection("votes")
        .get();
    for (let index = 0; index < votes.docs.length; index += 400) {
        const batch = db.batch();
        for (const doc of votes.docs.slice(index, index + 400)) {
            batch.delete(doc.ref);
        }
        await batch.commit();
    }
}
async function handlePollGroupMemberDeparture(db, groupRef, uid) {
    var _a;
    const groupSnap = await groupRef.get();
    if (!groupSnap.exists)
        return "left";
    const group = (_a = groupSnap.data()) !== null && _a !== void 0 ? _a : {};
    const memberIds = Array.isArray(group.memberIds)
        ? group.memberIds.filter((value) => typeof value === "string")
        : [];
    if (!memberIds.includes(uid))
        return "left";
    if (memberIds.length === 1) {
        await db.recursiveDelete(groupRef);
        return "groupDeleted";
    }
    const memberRef = groupRef.collection("members").doc(uid);
    if (group.createdBy !== uid) {
        const batch = db.batch();
        batch.update(groupRef, {
            memberIds: admin.firestore.FieldValue.arrayRemove(uid),
        });
        batch.delete(memberRef);
        (0, poll_group_activity_1.addPollGroupActivity)(batch, groupRef, {
            type: "member_left",
            actorUid: uid,
        });
        await batch.commit();
        return "left";
    }
    const membersSnap = await groupRef.collection("members").get();
    const remainingMembers = membersSnap.docs
        .filter((doc) => doc.id !== uid && memberIds.includes(doc.id))
        .map((doc) => {
        const data = doc.data();
        return { uid: doc.id, role: data.role, joinedAt: data.joinedAt };
    });
    const admins = remainingMembers
        .filter((member) => member.role === "admin")
        .sort((a, b) => {
        const aTime = a.joinedAt instanceof admin.firestore.Timestamp ? a.joinedAt.toMillis() : 0;
        const bTime = b.joinedAt instanceof admin.firestore.Timestamp ? b.joinedAt.toMillis() : 0;
        return aTime - bTime;
    });
    if (admins.length > 0) {
        const batch = db.batch();
        batch.update(groupRef, {
            createdBy: admins[0].uid,
            memberIds: admin.firestore.FieldValue.arrayRemove(uid),
            adminElectionStatus: null,
            adminElectionEndsAt: null,
        });
        batch.delete(memberRef);
        (0, poll_group_activity_1.addPollGroupActivity)(batch, groupRef, {
            type: "ownership_transferred",
            actorUid: uid,
            subjectUid: admins[0].uid,
        });
        await batch.commit();
        return "ownershipTransferred";
    }
    await clearElectionVotes(db, groupRef);
    const now = admin.firestore.Timestamp.now();
    const endsAt = admin.firestore.Timestamp.fromMillis(now.toMillis() + ELECTION_DURATION_MS);
    const candidateUids = remainingMembers.map((member) => member.uid);
    const batch = db.batch();
    batch.update(groupRef, {
        memberIds: admin.firestore.FieldValue.arrayRemove(uid),
        adminElectionStatus: "open",
        adminElectionEndsAt: endsAt,
    });
    batch.delete(memberRef);
    batch.set(groupRef.collection("adminElections").doc("current"), {
        status: "open",
        startedAt: now,
        endsAt,
        initiatedBy: uid,
        candidateUids,
        winnerUid: null,
    });
    (0, poll_group_activity_1.addPollGroupActivity)(batch, groupRef, {
        type: "admin_election_started",
        actorUid: uid,
        createdAt: now,
    });
    await batch.commit();
    return "electionStarted";
}
async function handleUserPollGroupDepartures(uid) {
    const db = admin.firestore();
    const groups = await db.collection("pollGroups").where("memberIds", "array-contains", uid).get();
    for (const group of groups.docs) {
        try {
            await handlePollGroupMemberDeparture(db, group.ref, uid);
        }
        catch (error) {
            console.error(`[groupDeparture] Failed to remove ${uid} from ${group.id}:`, error);
        }
    }
}
exports.leavePollGroup = (0, https_1.onCall)(async (request) => {
    var _a, _b;
    const uid = (_a = request.auth) === null || _a === void 0 ? void 0 : _a.uid;
    if (!uid)
        throw new https_1.HttpsError("unauthenticated", "Sign in before leaving a group.");
    const groupId = typeof ((_b = request.data) === null || _b === void 0 ? void 0 : _b.groupId) === "string" ? request.data.groupId.trim() : "";
    if (!groupId)
        throw new https_1.HttpsError("invalid-argument", "groupId is required.");
    const db = admin.firestore();
    const result = await handlePollGroupMemberDeparture(db, db.collection("pollGroups").doc(groupId), uid);
    return { result };
});
exports.castPollGroupAdminVote = (0, https_1.onCall)(async (request) => {
    var _a, _b, _c, _d, _e;
    const uid = (_a = request.auth) === null || _a === void 0 ? void 0 : _a.uid;
    if (!uid)
        throw new https_1.HttpsError("unauthenticated", "Sign in before voting.");
    const groupId = typeof ((_b = request.data) === null || _b === void 0 ? void 0 : _b.groupId) === "string" ? request.data.groupId.trim() : "";
    const candidateUid = typeof ((_c = request.data) === null || _c === void 0 ? void 0 : _c.candidateUid) === "string"
        ? request.data.candidateUid.trim()
        : "";
    if (!groupId || !candidateUid) {
        throw new https_1.HttpsError("invalid-argument", "groupId and candidateUid are required.");
    }
    const db = admin.firestore();
    const groupRef = db.collection("pollGroups").doc(groupId);
    const electionRef = groupRef.collection("adminElections").doc("current");
    const [groupSnap, electionSnap] = await Promise.all([groupRef.get(), electionRef.get()]);
    if (!groupSnap.exists || !electionSnap.exists) {
        throw new https_1.HttpsError("not-found", "Election not found.");
    }
    const group = (_d = groupSnap.data()) !== null && _d !== void 0 ? _d : {};
    const election = (_e = electionSnap.data()) !== null && _e !== void 0 ? _e : {};
    const memberIds = Array.isArray(group.memberIds) ? group.memberIds : [];
    const candidateUids = Array.isArray(election.candidateUids) ? election.candidateUids : [];
    if (!memberIds.includes(uid)) {
        throw new https_1.HttpsError("permission-denied", "Only group members can vote.");
    }
    if (election.status !== "open" ||
        !(election.endsAt instanceof admin.firestore.Timestamp) ||
        election.endsAt.toMillis() <= Date.now()) {
        throw new https_1.HttpsError("failed-precondition", "This election is closed.");
    }
    if (!candidateUids.includes(candidateUid) || !memberIds.includes(candidateUid)) {
        throw new https_1.HttpsError("invalid-argument", "Choose an active group member.");
    }
    await electionRef.collection("votes").doc(uid).set({
        voterUid: uid,
        candidateUid,
        castAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    return { candidateUid };
});
exports.finalizePollGroupAdminElections = (0, scheduler_1.onSchedule)("every 15 minutes", async () => {
    var _a, _b, _c, _d;
    const db = admin.firestore();
    const now = admin.firestore.Timestamp.now();
    const groups = await db
        .collection("pollGroups")
        .where("adminElectionStatus", "==", "open")
        .where("adminElectionEndsAt", "<=", now)
        .get();
    for (const groupSnap of groups.docs) {
        const groupRef = groupSnap.ref;
        const electionRef = groupRef.collection("adminElections").doc("current");
        const [electionSnap, membersSnap, votesSnap] = await Promise.all([
            electionRef.get(),
            groupRef.collection("members").get(),
            electionRef.collection("votes").get(),
        ]);
        if (!electionSnap.exists || ((_a = electionSnap.data()) === null || _a === void 0 ? void 0 : _a.status) !== "open")
            continue;
        const activeMemberIds = new Set(Array.isArray(groupSnap.data().memberIds) ? groupSnap.data().memberIds : []);
        const members = membersSnap.docs
            .filter((doc) => activeMemberIds.has(doc.id))
            .map((doc) => {
            const data = doc.data();
            return { uid: doc.id, role: data.role, joinedAt: data.joinedAt };
        })
            .sort((a, b) => {
            const aTime = a.joinedAt instanceof admin.firestore.Timestamp ? a.joinedAt.toMillis() : 0;
            const bTime = b.joinedAt instanceof admin.firestore.Timestamp ? b.joinedAt.toMillis() : 0;
            return aTime - bTime;
        });
        if (members.length === 0) {
            await db.recursiveDelete(groupRef);
            continue;
        }
        const counts = new Map();
        for (const vote of votesSnap.docs) {
            const data = vote.data();
            if (activeMemberIds.has(vote.id) && activeMemberIds.has(data.candidateUid)) {
                counts.set(data.candidateUid, ((_b = counts.get(data.candidateUid)) !== null && _b !== void 0 ? _b : 0) + 1);
            }
        }
        let winner = members[0];
        let winningVotes = (_c = counts.get(winner.uid)) !== null && _c !== void 0 ? _c : 0;
        for (const member of members.slice(1)) {
            const votes = (_d = counts.get(member.uid)) !== null && _d !== void 0 ? _d : 0;
            if (votes > winningVotes) {
                winner = member;
                winningVotes = votes;
            }
        }
        const batch = db.batch();
        batch.update(groupRef, {
            createdBy: winner.uid,
            adminElectionStatus: "closed",
            adminElectionEndsAt: null,
        });
        batch.update(groupRef.collection("members").doc(winner.uid), { role: "admin" });
        batch.update(electionRef, {
            status: "closed",
            winnerUid: winner.uid,
            resolvedAt: now,
        });
        (0, poll_group_activity_1.addPollGroupActivity)(batch, groupRef, {
            type: "admin_election_completed",
            actorUid: "system",
            subjectUid: winner.uid,
            createdAt: now,
        });
        await batch.commit();
    }
});
//# sourceMappingURL=poll_group_elections.js.map