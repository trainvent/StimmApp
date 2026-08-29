import { onSchedule } from "firebase-functions/v2/scheduler";
import { getApps, initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import {
	FieldValue,
	Firestore,
	Query,
	getFirestore,
} from "firebase-admin/firestore";
import { getStorage } from "firebase-admin/storage";
import { handleUserPollGroupDepartures } from "./poll_group_elections";

if (getApps().length === 0) {
	initializeApp();
}

/**
 * Helper function to delete a collection or subcollection in batches.
 */
async function deleteCollection(db: Firestore, collectionPath: string, batchSize: number) {
	const collectionRef = db.collection(collectionPath);
	const query = collectionRef.orderBy('__name__').limit(batchSize);

	return new Promise((resolve, reject) => {
		deleteQueryBatch(db, query, resolve).catch(reject);
	});
}

async function deleteQueryBatch(db: Firestore, query: Query, resolve: (value?: unknown) => void) {
	const snapshot = await query.get();

	const batchSize = snapshot.size;
	if (batchSize === 0) {
		// When there are no documents left, we are done
		resolve();
		return;
	}

	const batch = db.batch();
	snapshot.docs.forEach((doc) => {
		batch.delete(doc.ref);
	});
	await batch.commit();

	// Recurse on the next process tick, to avoid
	// exploding the stack.
	process.nextTick(() => {
		deleteQueryBatch(db, query, resolve);
	});
}

function getFilePathFromUrl(url: string): string | null {
	try {
		const parts = url.split("/o/");
		if (parts.length < 2) return null;
		const path = parts[1].split("?")[0];
		return decodeURIComponent(path);
	} catch (_e) {
		return null;
	}
}

/**
 * Reusable function to clean up all data associated with a user.
 */
export async function cleanupUserData(uid: string) {
	const db = getFirestore();
	const bucket = getStorage().bucket();

	console.log(`[cleanupUserData] Cleaning up data for user: ${uid}`);

	try {
		await handleUserPollGroupDepartures(uid);

		const profileSnap = await db.collection("users").doc(uid).get();
		const usernameKey = profileSnap.data()?.usernameKey;
		if (typeof usernameKey === "string" && usernameKey.trim().length > 0) {
			await db.collection("usernames").doc(usernameKey).delete();
		}

		// 1. Delete User Profile Document
		await db.collection("users").doc(uid).delete();

		// 2. Delete User Profile Picture from Storage
		try {
			await bucket.deleteFiles({ prefix: `users/${uid}/` });
			console.log(`[cleanupUserData] Deleted storage files in users/${uid}/`);
		} catch (e) {
			console.warn(`[cleanupUserData] Failed to delete storage files for user ${uid}:`, e);
		}

		// 3. Delete Petitions created by the user
		const petitionsSnap = await db.collection("petitions").where("createdBy", "==", uid).get();
		for (const doc of petitionsSnap.docs) {
			const data = doc.data();
			// Delete petition image
			if (data.imageUrl) {
				const filePath = getFilePathFromUrl(data.imageUrl);
				if (filePath) {
					try {
						await bucket.file(filePath).delete();
					} catch (e) {
						console.warn(`[cleanupUserData] Failed to delete petition image ${filePath}:`, e);
					}
				}
			}
			// Delete signatures subcollection
			await deleteCollection(db, `petitions/${doc.id}/signatures`, 100);
			// Delete the petition itself
			await doc.ref.delete();
		}

		// 4. Delete Polls created by the user
		const pollsSnap = await db.collection("polls").where("createdBy", "==", uid).get();
		for (const doc of pollsSnap.docs) {
			// Delete votes subcollection
			await deleteCollection(db, `polls/${doc.id}/votes`, 100);
			// Delete the poll itself
			await doc.ref.delete();
		}

		// 5. Delete Surveys created by the user
		const surveysSnap = await db.collection("surveys").where("createdBy", "==", uid).get();
		for (const doc of surveysSnap.docs) {
			// Delete responses subcollection
			await deleteCollection(db, `surveys/${doc.id}/responses`, 100);
			// Delete the survey itself
			await doc.ref.delete();
		}

		// 6. Delete Signatures made by this user on OTHER petitions
		const signaturesSnap = await db.collectionGroup("signatures").where("signerId", "==", uid).get();
		const sigBatch = db.batch();
		signaturesSnap.docs.forEach(doc => sigBatch.delete(doc.ref));
		await sigBatch.commit();

		// 7. Delete Votes made by this user on OTHER polls
		const votesSnap = await db.collectionGroup("votes").where("voterId", "==", uid).get();
		const voteBatch = db.batch();
		votesSnap.docs.forEach(doc => voteBatch.delete(doc.ref));
		await voteBatch.commit();

		// 8. Delete survey responses made by this user on OTHER surveys
		const responsesSnap = await db.collectionGroup("responses").where("uid", "==", uid).get();
		for (const responseDoc of responsesSnap.docs) {
			const surveyRef = responseDoc.ref.parent.parent;
			if (!surveyRef) continue;

			const data = responseDoc.data();
			const answers = data.answers || {};
			await db.runTransaction(async (txn) => {
				const update: Record<string, FieldValue> = {
					responseCount: FieldValue.increment(-1),
				};
				for (const [questionId, optionId] of Object.entries(answers)) {
					if (typeof optionId === "string") {
						update[`questionVotes.${questionId}.${optionId}`] = FieldValue.increment(-1);
					}
				}
				txn.update(surveyRef, update);
				txn.delete(responseDoc.ref);
				txn.delete(db.collection("users").doc(uid).collection("completedSurveys").doc(surveyRef.id));
			});
		}

		// 9. Delete Verification Codes
		await db.collection("verificationCodes").doc(uid).delete();

		console.log(`[cleanupUserData] Cleanup complete for user: ${uid}`);
	} catch (error) {
		console.error(`[cleanupUserData] Error cleaning up user ${uid}:`, error);
	}
}

// Using v1 for Auth trigger as v2 identity.beforeUserDeleted/onUserDeleted might not be available or configured correctly in this environment.
// Reverting to v1 to ensure stability.
import * as functions from "firebase-functions/v1";
export const onAccountDelete = functions.auth.user().onDelete(async (user) => {
	await cleanupUserData(user.uid);
});

/**
 * Scheduled function to check for orphaned users (exist in Firestore but not in Auth)
 * and clean them up. Runs every day at 14:00.
 */
export const cleanupOrphanedUsers = onSchedule({
    schedule: "every day 14:00",
    timeoutSeconds: 540,
    memory: "1GiB",
}, async (_event) => {
    const db = getFirestore();
    console.log("Starting cleanup of orphaned users...");

    // Get all user IDs from Firestore
    // Using select() to fetch only document references (IDs) to save memory
    const snapshot = await db.collection("users").select().get();
    const allUserIds = snapshot.docs.map(doc => doc.id);
    
    console.log(`Found ${allUserIds.length} users in Firestore. Checking Auth status...`);

    const BATCH_SIZE = 100;
    let orphanedCount = 0;

    for (let i = 0; i < allUserIds.length; i += BATCH_SIZE) {
        const batchIds = allUserIds.slice(i, i + BATCH_SIZE);
        const identifiers = batchIds.map(uid => ({ uid }));

        try {
            const authResult = await getAuth().getUsers(identifiers);
            const foundUids = new Set(authResult.users.map(u => u.uid));
            
            const missingUids = batchIds.filter(uid => !foundUids.has(uid));

            for (const missingUid of missingUids) {
                console.log(`User ${missingUid} is missing from Auth. Cleaning up...`);
                await cleanupUserData(missingUid);
                orphanedCount++;
            }
        } catch (error) {
            console.error(`Error checking auth status for batch starting at index ${i}:`, error);
        }
    }

    console.log(`Cleanup complete. Removed ${orphanedCount} orphaned users.`);
});
