import { onCall } from "firebase-functions/v2/https";
import * as admin from 'firebase-admin';
import * as fs from 'fs';
import * as path from 'path';

/**
 * A callable function to seed the database with test data from a JSON file.
 * This is intended for use in the Development environment only.
 * 
 * Usage from client:
 * await FirebaseFunctions.instance.httpsCallable('seedTestData').call();
 */
export const seedTestData = onCall(async (request) => {
    // 1. Safety Check: Ensure this only runs in the Dev project
    if (process.env.GCLOUD_PROJECT === 'stimmapp-f0141') {
        throw new admin.functions.https.HttpsError(
            'failed-precondition', 
            'This function can only be run in the development environment.'
        );
    }

    const db = admin.firestore();
    const batchManager = new BatchManager(db);

    try {
        // 2. Load the JSON file
        // Ensure you have a 'test_data.json' file in your functions/src directory (or copied to lib during build)
        const dataPath = path.join(__dirname, 'test_data.json');
        
        if (!fs.existsSync(dataPath)) {
             throw new admin.functions.https.HttpsError(
                'not-found',
                'Test data file (test_data.json) not found on server.'
            );
        }

        const rawData = fs.readFileSync(dataPath, 'utf-8');
        const testData = JSON.parse(rawData);

        console.log("Starting Test Data Seeding...");

        // 3. Seed Users
        if (testData.users) {
            for (const user of testData.users) {
                // Convert date strings to Timestamps if necessary
                if (user.createdAt) user.createdAt = admin.firestore.Timestamp.fromDate(new Date(user.createdAt));
                if (user.wentProAt) user.wentProAt = admin.firestore.Timestamp.fromDate(new Date(user.wentProAt));
                
                await batchManager.set(db.collection('users').doc(user.uid), user);
            }
            console.log(`Seeded ${testData.users.length} users.`);
        }

        // 4. Seed Petitions
        if (testData.petitions) {
            for (const petition of testData.petitions) {
                if (petition.createdAt) petition.createdAt = admin.firestore.Timestamp.fromDate(new Date(petition.createdAt));
                if (petition.expiresAt) petition.expiresAt = admin.firestore.Timestamp.fromDate(new Date(petition.expiresAt));

                const { signatures, ...petitionData } = petition;
                const petitionRef = db.collection('petitions').doc(petition.id);
                
                await batchManager.set(petitionRef, petitionData);

                // Seed Signatures subcollection
                if (signatures && Array.isArray(signatures)) {
                    for (const signature of signatures) {
                        if (signature.signedAt) signature.signedAt = admin.firestore.Timestamp.fromDate(new Date(signature.signedAt));
                        await batchManager.set(petitionRef.collection('signatures').doc(signature.uid), signature);
                    }
                }
            }
            console.log(`Seeded ${testData.petitions.length} petitions.`);
        }

        // 5. Seed Polls
        if (testData.polls) {
            for (const poll of testData.polls) {
                if (poll.createdAt) poll.createdAt = admin.firestore.Timestamp.fromDate(new Date(poll.createdAt));
                if (poll.expiresAt) poll.expiresAt = admin.firestore.Timestamp.fromDate(new Date(poll.expiresAt));

                const { votes, ...pollData } = poll;
                const pollRef = db.collection('polls').doc(poll.id);

                await batchManager.set(pollRef, pollData);

                // Seed Votes subcollection
                if (votes && Array.isArray(votes)) {
                    for (const vote of votes) {
                        if (vote.votedAt) vote.votedAt = admin.firestore.Timestamp.fromDate(new Date(vote.votedAt));
                        await batchManager.set(pollRef.collection('votes').doc(vote.uid), vote);
                    }
                }
            }
            console.log(`Seeded ${testData.polls.length} polls.`);
        }

        await batchManager.commit();
        console.log("Test Data Seeding Complete!");
        return { success: true, message: "Database seeded successfully." };

    } catch (error) {
        console.error("Error seeding database:", error);
        throw new admin.functions.https.HttpsError('internal', 'Failed to seed database.', error);
    }
});

/**
 * Helper class to manage Firestore batches (reused from data_sync.ts logic)
 */
class BatchManager {
    private batch: admin.firestore.WriteBatch;
    private count = 0;
    private db: admin.firestore.Firestore;

    constructor(db: admin.firestore.Firestore) {
        this.db = db;
        this.batch = db.batch();
    }

    async set(ref: admin.firestore.DocumentReference, data: any) {
        this.batch.set(ref, data);
        this.count++;
        if (this.count >= 400) {
            await this.commit();
        }
    }

    async commit() {
        if (this.count > 0) {
            await this.batch.commit();
            this.batch = this.db.batch();
            this.count = 0;
        }
    }
}
