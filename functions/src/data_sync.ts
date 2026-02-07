import { onSchedule } from "firebase-functions/v2/scheduler";
import * as admin from 'firebase-admin';
import { defineSecret } from "firebase-functions/params";

// Define the secret that will hold the Production Service Account Key
const prodServiceAccountKey = defineSecret("PROD_SERVICE_ACCOUNT_KEY");

interface CollectionSyncConfig {
    name: string;
    subcollections?: string[];
}

// List of Firestore collections to sync from Prod to Dev
const COLLECTIONS_TO_SYNC: CollectionSyncConfig[] = [
    { name: 'users' },
    { name: 'petitions', subcollections: ['signatures'] },
    { name: 'polls', subcollections: ['votes'] },
    { name: 'verificationCodes' }
];

/**
 * A scheduled function that runs once a day to copy data from the Production
 * environment to the Development environment.
 * 
 * WARNING: This function DELETES all data in the specified Dev collections
 * and Storage bucket before copying the data from Prod.
 */
export const syncProdToDev = onSchedule({
    schedule: "every day 03:00",
    timeoutSeconds: 540, // 9 minutes
    memory: "1GiB",
    secrets: [prodServiceAccountKey]
}, async (event) => {
    // Ensure we are NOT running in Production to prevent accidents
    if (process.env.GCLOUD_PROJECT === 'stimmapp-f0141') {
        console.error("CRITICAL: Attempted to run syncProdToDev IN PRODUCTION. Aborting.");
        return;
    }

    // Initialize access to the local (Dev) environment
    const devDb = admin.firestore();
    const devBucket = admin.storage().bucket();

    // Initialize a separate Firebase app instance for the Production project
    // using the service account key from the secret.
    const prodApp = admin.initializeApp({
        credential: admin.credential.cert(JSON.parse(prodServiceAccountKey.value())),
        // IMPORTANT: Replace with your REAL Production project's storage bucket URL
        storageBucket: "stimmapp-f0141.appspot.com" 
    }, "prodApp");

    const prodDb = prodApp.firestore();
    const prodBucket = prodApp.storage().bucket();

    console.log("Starting Sync: Production -> Development");

    // --- 1. Sync Firestore ---
    for (const config of COLLECTIONS_TO_SYNC) {
        const colName = config.name;
        console.log(`Syncing collection: ${colName}`);
        
        // A. Delete all documents in the Dev collection (including subcollections)
        // recursiveDelete is available in firebase-admin v11+
        await devDb.recursiveDelete(devDb.collection(colName));
        console.log(`Deleted all documents and subcollections from Dev: ${colName}`);

        // B. Copy all documents from Prod to Dev
        const snapshot = await prodDb.collection(colName).get();
        if (snapshot.empty) {
            console.log(`No documents to sync for ${colName}.`);
            continue;
        }

        const batchManager = new BatchManager(devDb);

        for (const doc of snapshot.docs) {
            await batchManager.set(devDb.collection(colName).doc(doc.id), doc.data());

            // C. Sync Subcollections if configured
            if (config.subcollections) {
                for (const subName of config.subcollections) {
                    const subSnapshot = await prodDb.collection(colName).doc(doc.id).collection(subName).get();
                    for (const subDoc of subSnapshot.docs) {
                        await batchManager.set(
                            devDb.collection(colName).doc(doc.id).collection(subName).doc(subDoc.id),
                            subDoc.data()
                        );
                    }
                }
            }
        }
        await batchManager.commit();
        console.log(`Synced documents (and subcollections) for ${colName}`);
    }

    // --- 2. Sync Firebase Storage ---
    console.log("Syncing Firebase Storage...");
    
    try {
        // A. Delete all files in the Dev bucket
        await devBucket.deleteFiles({ force: true });
        console.log("Deleted all files from Dev Storage bucket.");

        // B. Copy all files from Prod to Dev
        const [prodFiles] = await prodBucket.getFiles();
        if (prodFiles.length > 0) {
            let copiedCount = 0;
            for (const file of prodFiles) {
                await file.copy(devBucket.file(file.name));
                copiedCount++;
            }
            console.log(`Synced ${copiedCount} files from Storage.`);
        } else {
            console.log("No files to sync from Storage.");
        }
    } catch (error) {
        console.error("Error syncing storage:", error);
    }

    // Clean up the temporary prod app instance
    await prodApp.delete();

    // --- 3. Relink Users ---
    console.log("Relinking users...");
    await relinkUsers(devDb);

    console.log("Sync Complete!");
});

/**
 * Helper class to manage Firestore batches, automatically committing when the limit is reached.
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

    async delete(ref: admin.firestore.DocumentReference) {
        this.batch.delete(ref);
        this.count++;
        if (this.count >= 400) {
            await this.commit();
        }
    }

    async update(ref: admin.firestore.DocumentReference, data: any) {
        this.batch.update(ref, data);
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

/**
 * Relinks synced user data to existing Dev Authentication users.
 * 
 * Iterates through the 'users' collection (which contains Prod UIDs).
 * Checks if a user with the same email exists in Dev Auth.
 * If NOT found:
 *   Creates the user in Dev Auth with the Prod UID.
 * If FOUND but UID mismatch:
 *   Deletes the old Dev Auth user.
 *   Creates a new Dev Auth user with the Prod UID.
 */
async function relinkUsers(db: admin.firestore.Firestore) {
    const usersSnapshot = await db.collection('users').get();
    let relinkedCount = 0;

    console.log(`[Relink] Found ${usersSnapshot.size} users in Firestore to check.`);

    for (const userDoc of usersSnapshot.docs) {
        const userData = userDoc.data();
        const email = userData.email;
        const prodUid = userDoc.id;

        if (!email) {
            console.log(`[Relink] Skipping user ${prodUid} (no email)`);
            continue;
        }

        try {
            let devUser;
            try {
                devUser = await admin.auth().getUserByEmail(email);
            } catch (e: any) {
                if (e.code !== 'auth/user-not-found') throw e;
            }

            if (!devUser) {
                // Case 1: User does not exist in Dev Auth. Create it with Prod UID.
                console.log(`[Relink] Creating new Dev Auth user for ${email} with UID ${prodUid}`);
                await admin.auth().createUser({
                    uid: prodUid,
                    email: email,
                    emailVerified: true, // Auto-verify since it's from Prod
                    password: process.env.TEST_PASSWORD, // Default password for dev testing
                    displayName: userData.displayName,
                });
                relinkedCount++;
            } else if (devUser.uid !== prodUid) {
                // Case 2: User exists but UID mismatch. Delete and recreate.
                console.log(`[Relink] UID mismatch for ${email} (Dev: ${devUser.uid}, Prod: ${prodUid}). Recreating Auth user.`);
                
                await admin.auth().deleteUser(devUser.uid);
                
                await admin.auth().createUser({
                    uid: prodUid,
                    email: email,
                    emailVerified: true,
                    password: process.env.TEST_PASSWORD,
                    displayName: userData.displayName,
                });
                relinkedCount++;
            } else {
                // Case 3: User exists and UID matches. All good.
                console.log(`[Relink] User ${email} already correctly linked.`);
            }

        } catch (error) {
            console.error(`[Relink] Error processing user ${email}:`, error);
        }
    }
    
    console.log(`Relinked/Created ${relinkedCount} users in Dev Auth.`);
}
