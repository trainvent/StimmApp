import { onSchedule } from "firebase-functions/v2/scheduler";
import * as admin from 'firebase-admin';

admin.initializeApp();

export const checkSubscriptions = onSchedule("every day 00:00", async (event) => {
	const db = admin.firestore();
	const now = new Date();

	// Query all users who are currently Pro
	const snapshot = await db.collection('users').where('isPro', '==', true).get();

	console.log(`Found ${snapshot.size} Pro users to check.`);

	let batch = db.batch();
	let operationCount = 0;
	let revokedCount = 0;

	for (const doc of snapshot.docs) {
		const data = doc.data();
		// In Firestore, dates are stored as Timestamps
		const wentProAt = data.wentProAt as admin.firestore.Timestamp | undefined;

		let shouldRevoke = false;

		if (!wentProAt) {
			// Data inconsistency: marked as Pro but no start date. Revoke to fix state.
			shouldRevoke = true;
		} else {
			const startDate = wentProAt.toDate();
			// Calculate expiration: start date + 30 days
			const expirationDate = new Date(startDate);
			expirationDate.setDate(startDate.getDate() + 30);

			if (now > expirationDate) {
				shouldRevoke = true;
			}
		}

		if (shouldRevoke) {
			batch.update(doc.ref, {
				isPro: false,
				wentProAt: null,
				updatedAt: admin.firestore.FieldValue.serverTimestamp(),
			});

			operationCount++;
			revokedCount++;

			// Firestore batches allow up to 500 operations.
			if (operationCount >= 400) {
				await batch.commit();
				batch = db.batch();
				operationCount = 0;
			}
		}
	}

	if (operationCount > 0) {
		await batch.commit();
	}

	console.log(`Subscription check complete. Revoked ${revokedCount} memberships.`);
});

export const closeExpiredForms = onSchedule("every 15 minutes", async () => {
	const db = admin.firestore();
	const now = new Date();

	type CollectionTarget = {
		name: 'petitions' | 'polls' | 'surveys';
	};

	const targets: CollectionTarget[] = [
		{name: 'petitions'},
		{name: 'polls'},
		{name: 'surveys'},
	];

	for (const target of targets) {
		const closeMatching = async (
			status: 'active' | 'closing',
			dateField: 'expiresAt' | 'scheduledCloseAt',
		) => {
			const snap = await db
				.collection(target.name)
				.where('status', '==', status)
				.where(dateField, '<=', now)
				.get();

			if (snap.empty) {
				console.log(
					`[closeExpiredForms] No ${status} ${target.name} due by ${dateField}.`,
				);
				return;
			}

			let batch = db.batch();
			let opCount = 0;
			let closedCount = 0;

			for (const doc of snap.docs) {
				batch.update(doc.ref, {
					status: 'closed',
					scheduledCloseAt: admin.firestore.FieldValue.delete(),
					updatedAt: admin.firestore.FieldValue.serverTimestamp(),
				});
				opCount++;
				closedCount++;

				if (opCount >= 400) {
					await batch.commit();
					batch = db.batch();
					opCount = 0;
				}
			}

			if (opCount > 0) {
				await batch.commit();
			}

			console.log(
				`[closeExpiredForms] Closed ${closedCount} ${target.name} by ${dateField}.`,
			);
		};

		await closeMatching('active', 'expiresAt');
		await closeMatching('closing', 'expiresAt');
		await closeMatching('closing', 'scheduledCloseAt');
	}
});

export * from './user_cleanup';
export * from './admin';
export * from './auth_code';
export * from './data_sync';
export * from './poll_groups';
export * from './poll_group_elections';
export * from './share_page';

// Conditionally export test_data_seeder only if NOT in production
// Replace 'stimmapp-prod' with your actual production project ID if different
const PROD_PROJECT_ID = 'stimmapp-f0141'; 

if (process.env.GCLOUD_PROJECT !== PROD_PROJECT_ID) {
    // We use require here because 'export *' must be at top-level
    // This effectively "merges" the exports from test_data_seeder into this module
    const testDataSeeder = require('./test_data_seeder');
    Object.keys(testDataSeeder).forEach(key => {
        exports[key] = testDataSeeder[key];
    });
}
