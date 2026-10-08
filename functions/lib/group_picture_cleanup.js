"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.cleanupGroupPictures = void 0;
const firestore_1 = require("firebase-functions/v2/firestore");
const storage_1 = require("firebase-admin/storage");
// Also covers groups removed by account cleanup or the last member leaving.
exports.cleanupGroupPictures = (0, firestore_1.onDocumentDeleted)({ document: "pollGroups/{groupId}", retry: true }, async (event) => {
    await (0, storage_1.getStorage)().bucket().deleteFiles({
        prefix: `groups/${event.params.groupId}/profile/`,
    });
});
//# sourceMappingURL=group_picture_cleanup.js.map