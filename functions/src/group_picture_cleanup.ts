import { onDocumentDeleted } from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";

// Also covers groups removed by account cleanup or the last member leaving.
export const cleanupGroupPictures = onDocumentDeleted(
  { document: "pollGroups/{groupId}", retry: true },
  async (event) => {
    await admin.storage().bucket().deleteFiles({
      prefix: `groups/${event.params.groupId}/profile/`,
    });
  },
);
