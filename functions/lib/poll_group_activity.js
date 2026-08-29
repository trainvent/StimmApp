"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.addPollGroupActivity = addPollGroupActivity;
const firestore_1 = require("firebase-admin/firestore");
function addPollGroupActivity(batch, groupRef, activity) {
    var _a, _b, _c, _d, _e, _f;
    const ref = groupRef.collection("activities").doc();
    batch.set(ref, {
        type: activity.type,
        actorUid: activity.actorUid,
        actorDisplayName: (_a = activity.actorDisplayName) !== null && _a !== void 0 ? _a : null,
        subjectUid: (_b = activity.subjectUid) !== null && _b !== void 0 ? _b : null,
        subjectDisplayName: (_c = activity.subjectDisplayName) !== null && _c !== void 0 ? _c : null,
        targetTitle: (_d = activity.targetTitle) !== null && _d !== void 0 ? _d : null,
        count: (_e = activity.count) !== null && _e !== void 0 ? _e : null,
        createdAt: (_f = activity.createdAt) !== null && _f !== void 0 ? _f : firestore_1.Timestamp.now(),
    });
}
//# sourceMappingURL=poll_group_activity.js.map