const { initializeTestEnvironment, assertSucceeds, assertFails } = require('@firebase/rules-unit-testing');
const { doc, setDoc, updateDoc, arrayUnion, arrayRemove } = require('firebase/firestore');
const { ref, uploadBytes, getBytes, deleteObject } = require('firebase/storage');

(async () => {
  const env = await initializeTestEnvironment({projectId: 'demo-stimmapp-pictures'});
  const authenticated = uid => env.authenticatedContext(uid, {email: `${uid}@example.test`, email_verified: true});
  try {
    await env.withSecurityRulesDisabled(async context => {
      const db = context.firestore();
      await setDoc(doc(db, 'pollGroups/team'), {
        createdBy: 'owner', memberIds: ['owner', 'admin', 'member'], accessMode: 'private',
      });
      await setDoc(doc(db, 'pollGroups/team/members/admin'), {role: 'admin'});
      await setDoc(doc(db, 'pollGroups/team/members/member'), {role: 'user'});
    });
    const storage = uid => uid ? authenticated(uid).storage() : env.unauthenticatedContext().storage();
    const picture = uid => ref(storage(uid), 'groups/team/profile/avatar.png');
    const bytes = new Uint8Array([137, 80, 78, 71]);
    const metadata = {contentType: 'image/png'};
    await assertSucceeds(uploadBytes(picture('owner'), bytes, metadata));
    await assertSucceeds(uploadBytes(picture('admin'), bytes, metadata));
    for (const uid of ['member', 'stranger', null]) {
      await assertFails(uploadBytes(picture(uid), bytes, metadata));
      await assertFails(deleteObject(picture(uid)));
    }
    await assertSucceeds(getBytes(picture('member')));
    await assertFails(getBytes(picture('stranger')));
    await assertFails(getBytes(picture(null)));
    await assertFails(uploadBytes(picture('owner'), bytes, {contentType: 'text/plain'}));
    await assertFails(uploadBytes(picture('owner'), new Uint8Array(5 * 1024 * 1024), metadata));
    await assertFails(uploadBytes(ref(storage('owner'), 'groups/missing/profile/a.png'), bytes, metadata));
    await assertSucceeds(updateDoc(doc(authenticated('admin').firestore(), 'pollGroups/team'), {profilePictureUrl: 'https://example.test/avatar.png'}));
    await assertFails(updateDoc(doc(authenticated('member').firestore(), 'pollGroups/team'), {profilePictureUrl: 'https://example.test/other.png'}));
    await assertFails(updateDoc(doc(authenticated('member').firestore(), 'pollGroups/team'), {memberIds: arrayRemove('member'), injectedPicture: 'x'}));
    await assertFails(updateDoc(doc(authenticated('stranger').firestore(), 'pollGroups/team'), {memberIds: arrayUnion('stranger'), injectedPicture: 'x'}));
    await assertSucceeds(updateDoc(doc(authenticated('stranger').firestore(), 'pollGroups/team'), {memberIds: arrayUnion('stranger')}));
    await assertSucceeds(updateDoc(doc(authenticated('member').firestore(), 'pollGroups/team'), {memberIds: arrayRemove('member')}));
    await assertSucceeds(deleteObject(picture('admin')));
    console.log('Group picture rules: owner/admin uploads and deletion, read access, size/type limits, and membership field protection passed.');
  } finally {
    await env.cleanup();
  }
})().catch(error => { console.error(error); process.exitCode = 1; });
