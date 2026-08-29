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
var __exportStar = (this && this.__exportStar) || function(m, exports) {
    for (var p in m) if (p !== "default" && !Object.prototype.hasOwnProperty.call(exports, p)) __createBinding(exports, m, p);
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.closeExpiredForms = exports.checkSubscriptions = void 0;
const scheduler_1 = require("firebase-functions/v2/scheduler");
const app_1 = require("firebase-admin/app");
const firestore_1 = require("firebase-admin/firestore");
(0, app_1.initializeApp)();
exports.checkSubscriptions = (0, scheduler_1.onSchedule)("every day 00:00", async (_event) => {
    const db = (0, firestore_1.getFirestore)();
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
        const wentProAt = data.wentProAt;
        let shouldRevoke = false;
        if (!wentProAt) {
            // Data inconsistency: marked as Pro but no start date. Revoke to fix state.
            shouldRevoke = true;
        }
        else {
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
                updatedAt: firestore_1.FieldValue.serverTimestamp(),
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
exports.closeExpiredForms = (0, scheduler_1.onSchedule)("every 15 minutes", async () => {
    const db = (0, firestore_1.getFirestore)();
    const now = new Date();
    const targets = [
        { name: 'petitions' },
        { name: 'polls' },
        { name: 'surveys' },
    ];
    for (const target of targets) {
        const closeMatching = async (status, dateField) => {
            const snap = await db
                .collection(target.name)
                .where('status', '==', status)
                .where(dateField, '<=', now)
                .get();
            if (snap.empty) {
                console.log(`[closeExpiredForms] No ${status} ${target.name} due by ${dateField}.`);
                return;
            }
            let batch = db.batch();
            let opCount = 0;
            let closedCount = 0;
            for (const doc of snap.docs) {
                batch.update(doc.ref, {
                    status: 'closed',
                    scheduledCloseAt: firestore_1.FieldValue.delete(),
                    updatedAt: firestore_1.FieldValue.serverTimestamp(),
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
            console.log(`[closeExpiredForms] Closed ${closedCount} ${target.name} by ${dateField}.`);
        };
        await closeMatching('active', 'expiresAt');
        await closeMatching('closing', 'expiresAt');
        await closeMatching('closing', 'scheduledCloseAt');
    }
});
__exportStar(require("./user_cleanup"), exports);
__exportStar(require("./admin"), exports);
__exportStar(require("./auth_code"), exports);
__exportStar(require("./data_sync"), exports);
__exportStar(require("./poll_groups"), exports);
__exportStar(require("./poll_group_elections"), exports);
__exportStar(require("./share_page"), exports);
__exportStar(require("./pid_verification"), exports);
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
//# sourceMappingURL=index.js.map