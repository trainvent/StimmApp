import { onSchedule } from "firebase-functions/v2/scheduler";
import * as admin from 'firebase-admin';
import { defineSecret } from "firebase-functions/params";

// Define the secret that will hold the Production Service Account Key
const prodServiceAccountKey = defineSecret("PROD_SERVICE_ACCOUNT_KEY");

// List of Firestore collections to sync from Prod to Dev
const COLLECTIONS_TO_SYNC = ['users', 'petitions', 'polls', 'verificationCodes']; 

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
    for (const colName of COLLECTIONS_TO_SYNC) {
        console.log(`Syncing collection: ${colName}`);
        
        // A. Delete all documents in the Dev collection
        await deleteCollection(devDb, colName, 200);
        console.log(`Deleted all documents from Dev collection: ${colName}`);

        // B. Copy all documents from Prod to Dev
        const snapshot = await prodDb.collection(colName).get();
        if (snapshot.empty) {
            console.log(`No documents to sync for ${colName}.`);
            continue;
        }

        const batchSize = 400;
        let batch = devDb.batch();
        let count = 0;

        for (const doc of snapshot.docs) {
            batch.set(devDb.collection(colName).doc(doc.id), doc.data());
            count++;
            if (count >= batchSize) {
                await batch.commit();
                batch = devDb.batch();
                count = 0;
            }
        }
        if (count > 0) await batch.commit();
        console.log(`Synced ${snapshot.size} documents for ${colName}`);
    }

    // --- 2. Sync Firebase Storage ---
    console.log("Syncing Firebase Storage...");
    
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

    // Clean up the temporary prod app instance
    await prodApp.delete();

    console.log("Sync Complete!");
});

/**
 * Deletes all documents in a collection in batches.
 */
async function deleteCollection(db: admin.firestore.Firestore, collectionPath: string, batchSize: number) {
  const collectionRef = db.collection(collectionPath);
  const query = collectionRef.orderBy('__name__').limit(batchSize);

  return new Promise<void>((resolve, reject) => {
    deleteQueryBatch(db, query, resolve).catch(reject);
  });
}

async function deleteQueryBatch(db: admin.firestore.Firestore, query: admin.firestore.Query, resolve: Function) {
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

  // Recurse on the next process tick to avoid exploding the stack
  process.nextTick(() => {
    deleteQueryBatch(db, query, resolve);
  });
}
