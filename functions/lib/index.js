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
var __exportStar = (this && this.__exportStar) || function(m, exports) {
    for (var p in m) if (p !== "default" && !Object.prototype.hasOwnProperty.call(exports, p)) __createBinding(exports, m, p);
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.closeExpiredForms = exports.checkSubscriptions = void 0;
const scheduler_1 = require("firebase-functions/v2/scheduler");
const admin = __importStar(require("firebase-admin"));
admin.initializeApp();
exports.checkSubscriptions = (0, scheduler_1.onSchedule)("every day 00:00", async (event) => {
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
exports.closeExpiredForms = (0, scheduler_1.onSchedule)("every 15 minutes", async () => {
    const db = admin.firestore();
    const now = new Date();
    const targets = [
        { name: 'petitions' },
        { name: 'polls' },
    ];
    for (const target of targets) {
        const snap = await db
            .collection(target.name)
            .where('status', '==', 'active')
            .where('expiresAt', '<=', now)
            .get();
        if (snap.empty) {
            console.log(`[closeExpiredForms] No expired active ${target.name}.`);
            continue;
        }
        let batch = db.batch();
        let opCount = 0;
        let closedCount = 0;
        for (const doc of snap.docs) {
            batch.update(doc.ref, {
                status: 'closed',
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            opCount++;
            closedCount++;
            // Keep margin below Firestore's 500 writes per batch limit.
            if (opCount >= 400) {
                await batch.commit();
                batch = db.batch();
                opCount = 0;
            }
        }
        if (opCount > 0) {
            await batch.commit();
        }
        console.log(`[closeExpiredForms] Closed ${closedCount} ${target.name}.`);
    }
});
__exportStar(require("./user_cleanup"), exports);
__exportStar(require("./admin"), exports);
__exportStar(require("./auth_code"), exports);
__exportStar(require("./data_sync"), exports);
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