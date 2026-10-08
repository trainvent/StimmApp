"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.cleanupPetitionCommentLikes = void 0;
const firestore_1 = require("firebase-functions/v2/firestore");
const firestore_2 = require("firebase-admin/firestore");
// Firestore document deletion does not remove nested like documents.
exports.cleanupPetitionCommentLikes = (0, firestore_1.onDocumentDeleted)('petitions/{petitionId}/signatures/{signerId}', async (event) => {
    if (!event.data)
        return;
    await (0, firestore_2.getFirestore)().recursiveDelete(event.data.ref.collection('commentLikes'));
});
//# sourceMappingURL=petition_comment_cleanup.js.map