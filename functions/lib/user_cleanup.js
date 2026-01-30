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
exports.cleanupOrphanedUsers = exports.onAccountDelete = void 0;
exports.cleanupUserData = cleanupUserData;
const functions = __importStar(require("firebase-functions/v1"));
const scheduler_1 = require("firebase-functions/v2/scheduler");
const admin = __importStar(require("firebase-admin"));
if (admin.apps.length === 0) {
    admin.initializeApp();
}
/**
 * Helper function to delete a collection or subcollection in batches.
 */
async function deleteCollection(db, collectionPath, batchSize) {
    const collectionRef = db.collection(collectionPath);
    const query = collectionRef.orderBy('__name__').limit(batchSize);
    return new Promise((resolve, reject) => {
        deleteQueryBatch(db, query, resolve).catch(reject);
    });
}
async function deleteQueryBatch(db, query, resolve) {
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
function getFilePathFromUrl(url) {
    try {
        const parts = url.split("/o/");
        if (parts.length < 2)
            return null;
        const path = parts[1].split("?")[0];
        return decodeURIComponent(path);
    }
    catch (e) {
        return null;
    }
}
/**
 * Reusable function to clean up all data associated with a user.
 */
async function cleanupUserData(uid) {
    const db = admin.firestore();
    const bucket = admin.storage().bucket();
    console.log(`[cleanupUserData] Cleaning up data for user: ${uid}`);
    try {
        // 1. Delete User Profile Document
        await db.collection("users").doc(uid).delete();
        // 2. Delete User Profile Picture from Storage
        try {
            await bucket.deleteFiles({ prefix: `users/${uid}/` });
            console.log(`[cleanupUserData] Deleted storage files in users/${uid}/`);
        }
        catch (e) {
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
                    }
                    catch (e) {
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
        // 5. Delete Signatures made by this user on OTHER petitions
        const signaturesSnap = await db.collectionGroup("signatures").where("signerId", "==", uid).get();
        const sigBatch = db.batch();
        signaturesSnap.docs.forEach(doc => sigBatch.delete(doc.ref));
        await sigBatch.commit();
        // 6. Delete Votes made by this user on OTHER polls
        const votesSnap = await db.collectionGroup("votes").where("voterId", "==", uid).get();
        const voteBatch = db.batch();
        votesSnap.docs.forEach(doc => voteBatch.delete(doc.ref));
        await voteBatch.commit();
        // 7. Delete Verification Codes
        await db.collection("verificationCodes").doc(uid).delete();
        console.log(`[cleanupUserData] Cleanup complete for user: ${uid}`);
    }
    catch (error) {
        console.error(`[cleanupUserData] Error cleaning up user ${uid}:`, error);
    }
}
exports.onAccountDelete = functions.auth.user().onDelete(async (user) => {
    await cleanupUserData(user.uid);
});
/**
 * Scheduled function to check for orphaned users (exist in Firestore but not in Auth)
 * and clean them up. Runs every day at 14:00.
 */
exports.cleanupOrphanedUsers = (0, scheduler_1.onSchedule)({
    schedule: "every day 14:00",
    timeoutSeconds: 540,
    memory: "1GiB",
}, async (event) => {
    const db = admin.firestore();
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
            const authResult = await admin.auth().getUsers(identifiers);
            const foundUids = new Set(authResult.users.map(u => u.uid));
            const missingUids = batchIds.filter(uid => !foundUids.has(uid));
            for (const missingUid of missingUids) {
                console.log(`User ${missingUid} is missing from Auth. Cleaning up...`);
                await cleanupUserData(missingUid);
                orphanedCount++;
            }
        }
        catch (error) {
            console.error(`Error checking auth status for batch starting at index ${i}:`, error);
        }
    }
    console.log(`Cleanup complete. Removed ${orphanedCount} orphaned users.`);
});
//# sourceMappingURL=user_cleanup.js.map