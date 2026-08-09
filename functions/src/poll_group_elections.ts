import { HttpsError, onCall } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";
import * as admin from "firebase-admin";
import { addPollGroupActivity } from "./poll_group_activity";

const ELECTION_DURATION_MS = 3 * 24 * 60 * 60 * 1000;

type DepartureResult = "left" | "groupDeleted" | "ownershipTransferred" | "electionStarted";
type ElectionMember = {
	uid: string;
	role?: unknown;
	joinedAt?: unknown;
};

async function clearElectionVotes(
	db: admin.firestore.Firestore,
	groupRef: admin.firestore.DocumentReference,
) {
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

export async function handlePollGroupMemberDeparture(
	db: admin.firestore.Firestore,
	groupRef: admin.firestore.DocumentReference,
	uid: string,
): Promise<DepartureResult> {
	const groupSnap = await groupRef.get();
	if (!groupSnap.exists) return "left";
	const group = groupSnap.data() ?? {};
	const memberIds = Array.isArray(group.memberIds)
		? group.memberIds.filter((value): value is string => typeof value === "string")
		: [];
	if (!memberIds.includes(uid)) return "left";

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
		addPollGroupActivity(batch, groupRef, {
			type: "member_left",
			actorUid: uid,
		});
		await batch.commit();
		return "left";
	}

	const membersSnap = await groupRef.collection("members").get();
	const remainingMembers = membersSnap.docs
		.filter((doc) => doc.id !== uid && memberIds.includes(doc.id))
		.map((doc): ElectionMember => {
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
		addPollGroupActivity(batch, groupRef, {
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
	addPollGroupActivity(batch, groupRef, {
		type: "admin_election_started",
		actorUid: uid,
		createdAt: now,
	});
	await batch.commit();
	return "electionStarted";
}

export async function handleUserPollGroupDepartures(uid: string) {
	const db = admin.firestore();
	const groups = await db.collection("pollGroups").where("memberIds", "array-contains", uid).get();
	for (const group of groups.docs) {
		try {
			await handlePollGroupMemberDeparture(db, group.ref, uid);
		} catch (error) {
			console.error(`[groupDeparture] Failed to remove ${uid} from ${group.id}:`, error);
		}
	}
}

export const leavePollGroup = onCall(async (request) => {
	const uid = request.auth?.uid;
	if (!uid) throw new HttpsError("unauthenticated", "Sign in before leaving a group.");
	const groupId = typeof request.data?.groupId === "string" ? request.data.groupId.trim() : "";
	if (!groupId) throw new HttpsError("invalid-argument", "groupId is required.");
	const db = admin.firestore();
	const result = await handlePollGroupMemberDeparture(
		db,
		db.collection("pollGroups").doc(groupId),
		uid,
	);
	return { result };
});

export const castPollGroupAdminVote = onCall(async (request) => {
	const uid = request.auth?.uid;
	if (!uid) throw new HttpsError("unauthenticated", "Sign in before voting.");
	const groupId = typeof request.data?.groupId === "string" ? request.data.groupId.trim() : "";
	const candidateUid = typeof request.data?.candidateUid === "string"
		? request.data.candidateUid.trim()
		: "";
	if (!groupId || !candidateUid) {
		throw new HttpsError("invalid-argument", "groupId and candidateUid are required.");
	}

	const db = admin.firestore();
	const groupRef = db.collection("pollGroups").doc(groupId);
	const electionRef = groupRef.collection("adminElections").doc("current");
	const [groupSnap, electionSnap] = await Promise.all([groupRef.get(), electionRef.get()]);
	if (!groupSnap.exists || !electionSnap.exists) {
		throw new HttpsError("not-found", "Election not found.");
	}
	const group = groupSnap.data() ?? {};
	const election = electionSnap.data() ?? {};
	const memberIds = Array.isArray(group.memberIds) ? group.memberIds : [];
	const candidateUids = Array.isArray(election.candidateUids) ? election.candidateUids : [];
	if (!memberIds.includes(uid)) {
		throw new HttpsError("permission-denied", "Only group members can vote.");
	}
	if (election.status !== "open" ||
		!(election.endsAt instanceof admin.firestore.Timestamp) ||
		election.endsAt.toMillis() <= Date.now()) {
		throw new HttpsError("failed-precondition", "This election is closed.");
	}
	if (!candidateUids.includes(candidateUid) || !memberIds.includes(candidateUid)) {
		throw new HttpsError("invalid-argument", "Choose an active group member.");
	}

	await electionRef.collection("votes").doc(uid).set({
		voterUid: uid,
		candidateUid,
		castAt: admin.firestore.FieldValue.serverTimestamp(),
	});
	return { candidateUid };
});

export const finalizePollGroupAdminElections = onSchedule("every 15 minutes", async () => {
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
		if (!electionSnap.exists || electionSnap.data()?.status !== "open") continue;
		const activeMemberIds = new Set(
			Array.isArray(groupSnap.data().memberIds) ? groupSnap.data().memberIds : [],
		);
		const members = membersSnap.docs
			.filter((doc) => activeMemberIds.has(doc.id))
			.map((doc): ElectionMember => {
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

		const counts = new Map<string, number>();
		for (const vote of votesSnap.docs) {
			const data = vote.data();
			if (activeMemberIds.has(vote.id) && activeMemberIds.has(data.candidateUid)) {
				counts.set(data.candidateUid, (counts.get(data.candidateUid) ?? 0) + 1);
			}
		}
		let winner = members[0];
		let winningVotes = counts.get(winner.uid) ?? 0;
		for (const member of members.slice(1)) {
			const votes = counts.get(member.uid) ?? 0;
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
		addPollGroupActivity(batch, groupRef, {
			type: "admin_election_completed",
			actorUid: "system",
			subjectUid: winner.uid,
			createdAt: now,
		});
		await batch.commit();
	}
});
