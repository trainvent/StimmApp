import { onDocumentDeleted } from 'firebase-functions/v2/firestore';
import * as admin from 'firebase-admin';

// Firestore document deletion does not remove nested like documents.
export const cleanupPetitionCommentLikes = onDocumentDeleted(
    'petitions/{petitionId}/signatures/{signerId}',
    async event => {
        if (!event.data) return;
        await admin.firestore().recursiveDelete(event.data.ref.collection('commentLikes'));
    },
);
