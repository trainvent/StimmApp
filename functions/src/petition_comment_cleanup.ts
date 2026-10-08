import { onDocumentDeleted } from 'firebase-functions/v2/firestore';
import { getFirestore } from 'firebase-admin/firestore';

// Firestore document deletion does not remove nested like documents.
export const cleanupPetitionCommentLikes = onDocumentDeleted(
    'petitions/{petitionId}/signatures/{signerId}',
    async event => {
        if (!event.data) return;
        await getFirestore().recursiveDelete(event.data.ref.collection('commentLikes'));
    },
);
