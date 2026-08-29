import {
	DocumentReference,
	Timestamp,
	WriteBatch,
} from "firebase-admin/firestore";

type PollGroupActivityInput = {
	type: string;
	actorUid: string;
	actorDisplayName?: string | null;
	subjectUid?: string | null;
	subjectDisplayName?: string | null;
	targetTitle?: string | null;
	count?: number | null;
	createdAt?: Timestamp;
};

export function addPollGroupActivity(
	batch: WriteBatch,
	groupRef: DocumentReference,
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
		createdAt: activity.createdAt ?? Timestamp.now(),
	});
}
