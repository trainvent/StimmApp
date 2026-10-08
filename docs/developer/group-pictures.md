# Group profile pictures

The group editor supports choosing, replacing, and removing a picture. Changes
are applied on Save. Images are resized and re-encoded as PNG, limited to less
than 5 MiB, and uploaded to `groups/<groupId>/profile/<uuid>.png`. Group documents
store the download URL in the optional `profilePictureUrl` field.

Owners and group admins can upload/delete images. Storage reads follow group
visibility: members and the owner can read private group pictures; signed-in
users can read pictures for non-private groups. As with user profile pictures,
Firebase download URLs are bearer URLs and should only be shared where the
group is visible.

The editor deletes replaced images after saving the new URL. Failed metadata
writes clean up the newly uploaded image. A failed picture upload preserves the
saved group and the pending selection so Save retries the existing group.
`cleanupGroupPictures` deletes the group's picture folder when its Firestore
document is deleted, including account cleanup and the last member leaving.

## Deployment

Deploy the backend changes before releasing the app. Choose the intended
project explicitly; do not deploy both environments by accident.

```bash
firebase deploy --only storage,firestore:rules,functions:cleanupGroupPictures --project dev
# For the production release, use --project prod instead.
```

The Storage rules now consult Firestore for owner/admin membership. On the first
deployment Firebase may ask to enable the service permission needed for this
cross-service lookup. Do not replace that check with public writes.

## Local verification

Requires Java 21+ and the Firebase CLI. The dedicated config uses an isolated
`demo-` project and ports 8189 (Firestore) and 9299 (Storage); it does not deploy
or access live project resources.

```bash
npm --prefix test/security ci
npm --prefix test/security test
npm --prefix functions ci
npm --prefix functions run build
flutter test test/core/data/models/poll_group_test.dart test/app/mobile/pages/main/home/creator/poll_groups_page_test.dart
```
