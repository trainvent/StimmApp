import * as admin from "firebase-admin";

type PollGroupActivityInput = {
	type: string;
	actorUid: string;
	actorDisplayName?: string | null;
	subjectUid?: string | null;
	subjectDisplayName?: string | null;
	targetTitle?: string | null;
	count?: number | null;
	createdAt?: admin.firestore.Timestamp;
};

export function addPollGroupActivity(
	batch: admin.firestore.WriteBatch,
	groupRef: admin.firestore.DocumentReference,
	activity: PollGroupActivityInput,
) {
	const ref = groupRef.collection("activities").doc();
	batch.set(ref, {
		type: activity.type,
		actorUid: activity.actorUid,
		actorDisplayName: activity.actorDisplayName ?? null,
		subjectUid: activity.subjectUid ?? null,
		subjectDisplayName: activity.subjectDisplayName ?? null,
		targetTitle: activity.targetTitle ?? null,
		count: activity.count ?? null,
		createdAt: activity.createdAt ?? admin.firestore.Timestamp.now(),
	});
}
