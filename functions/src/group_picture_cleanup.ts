import { onDocumentDeleted } from "firebase-functions/v2/firestore";
import { getStorage } from "firebase-admin/storage";

// Also covers groups removed by account cleanup or the last member leaving.
export const cleanupGroupPictures = onDocumentDeleted(
  { document: "pollGroups/{groupId}", retry: true },
  async (event) => {
    await getStorage().bucket().deleteFiles({
      prefix: `groups/${event.params.groupId}/profile/`,
    });
  },
);
