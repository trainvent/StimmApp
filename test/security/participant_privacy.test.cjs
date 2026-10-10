const assert = require('node:assert/strict');
const {initializeTestEnvironment, assertSucceeds, assertFails} = require('@firebase/rules-unit-testing');
const {doc, getDoc, setDoc, updateDoc, collection, getDocs} = require('firebase/firestore');
const admin = require('../../functions/node_modules/firebase-admin');
admin.initializeApp({projectId: 'demo-stimmapp-pictures'});
const privacy = require('../../functions/lib/participant_privacy');

(async () => {
  const env = await initializeTestEnvironment({projectId: 'demo-stimmapp-pictures'});
  try {
    await env.withSecurityRulesDisabled(async ctx => {
      const db = ctx.firestore();
      await setDoc(doc(db, 'users/hidden'), {
        displayName: 'Hidden name', givenName: 'Full', surname: 'Identity',
        email: 'hidden@example.com', address: 'Private address', state: null,
        signAnonymously: true, profilePictureUrl: 'https://example.com/hidden.jpg',
      });
      await setDoc(doc(db, 'users/public'), {displayName: 'Public name', signAnonymously: false});
      for (const [type, child] of [['petitions','signatures'], ['polls','votes'], ['surveys','responses']]) {
        await setDoc(doc(db, type + '/form'), {createdBy: 'creator', title: 'Form', visibility: 'public'});
        await setDoc(doc(db, type + '/form/' + child + '/hidden'), {uid: 'hidden', reason: 'Private reason'});
        await setDoc(doc(db, type + '/form/' + child + '/public'), {uid: 'public', reason: 'Public reason'});
      }
    });
    const guest = env.unauthenticatedContext().firestore();
    const stranger = env.authenticatedContext('stranger', {email: 'stranger@example.com'}).firestore();
    const owner = env.authenticatedContext('hidden', {email: 'hidden@example.com'}).firestore();
    const creator = env.authenticatedContext('creator', {email: 'creator@example.com'}).firestore();
    await assertFails(getDoc(doc(guest, 'users/hidden')));
    await assertFails(getDoc(doc(stranger, 'users/public')));
    await assertSucceeds(getDoc(doc(owner, 'users/hidden')));
    await assertFails(getDoc(doc(stranger, 'petitions/form/signatures/hidden')));
    await assertSucceeds(getDoc(doc(owner, 'petitions/form/signatures/hidden')));
    await assertFails(getDocs(collection(guest, 'petitions/form/signatures')));
    await assertSucceeds(getDocs(collection(creator, 'petitions/form/signatures')));
    await assertFails(getDocs(collection(stranger, 'polls/form/votes')));
    await assertFails(getDoc(doc(stranger, 'polls/form/votes/hidden')));
    await assertFails(getDocs(collection(stranger, 'surveys/form/responses')));
    // A stranger must not steal creator status to pass evaluator authorization.
    for (const type of ['petitions', 'polls', 'surveys']) {
      await assertFails(updateDoc(doc(stranger, type + '/form'), {createdBy: 'stranger'}));
    }
    for (const type of ['petition', 'poll', 'survey']) {
      const data = {type, formId: 'form'};
      const publicRows = await privacy.getPublicParticipants.run({data});
      const hidden = publicRows.entries.find(row => row.profile.signAnonymously);
      assert.deepEqual(hidden, {profile: {uid: '', signAnonymously: true}});
      assert.equal(JSON.stringify(publicRows).includes('hidden'), false);
      assert.equal(JSON.stringify(publicRows).includes('Private'), false);
      await assert.rejects(privacy.getParticipantResults.run({data}), {code: 'unauthenticated'});
      await assert.rejects(privacy.getParticipantResults.run({data, auth: {uid: 'stranger', token: {}}}), {code: 'permission-denied'});
      const full = await privacy.getParticipantResults.run({data, auth: {uid: 'creator', token: {}}});
      const identity = full.entries.find(row => row.profile.uid === 'hidden');
      assert.equal(identity.profile.email, 'hidden@example.com');
      assert.equal(identity.profile.givenName, 'Full');
      assert.equal(identity.reason, 'Private reason');
      const adminRows = await privacy.getParticipantResults.run({data,
        auth: {uid: 'admin', token: {email: 'service@trainvent.com'}}});
      assert.equal(adminRows.entries.length, 2);
    }
    await env.withSecurityRulesDisabled(async ctx => {
      await setDoc(doc(ctx.firestore(), 'pollGroups/private-group'), {memberIds: ['member']});
      await setDoc(doc(ctx.firestore(), 'polls/private-form'), {
        createdBy: 'creator', visibility: 'group', groupId: 'private-group',
      });
    });
    const privateData = {type: 'poll', formId: 'private-form'};
    await assert.rejects(privacy.getPublicParticipants.run({data: privateData}),
      {code: 'permission-denied'});
    await assert.rejects(privacy.getPublicParticipants.run({data: privateData,
      auth: {uid: 'stranger', token: {}}}), {code: 'permission-denied'});
    assert.deepEqual((await privacy.getPublicParticipants.run({data: privateData,
      auth: {uid: 'member', token: {}}})).entries, []);
    await assert.rejects(privacy.getParticipantResults.run({data: privateData,
      auth: {uid: 'member', token: {}}}), {code: 'permission-denied'});
    await assert.rejects(privacy.getPublicParticipants.run({data: {
      type: 'petition', formId: 'form', offset: -1,
    }}), {code: 'invalid-argument'});
    const profile = await privacy.getPublicProfile.run({data: {uid: 'hidden'}});
    assert.deepEqual(Object.keys(profile).sort(), ['displayName', 'profilePictureUrl', 'uid']);
    await assertSucceeds(updateDoc(doc(owner, 'users/hidden'), {signAnonymously: false}));
    const visible = await privacy.getPublicParticipants.run({data: {type: 'petition', formId: 'form'}});
    assert.equal(visible.entries.some(row => row.profile.uid === 'hidden'), true);
    await assertSucceeds(updateDoc(doc(owner, 'users/hidden'), {signAnonymously: true}));
    const hiddenAgain = await privacy.getPublicParticipants.run({data: {type: 'petition', formId: 'form'}});
    assert.equal(hiddenAgain.entries.some(row => row.profile.uid === 'hidden'), false);
    console.log('Privacy rules and callable authorization passed for petitions, polls and surveys.');
  } finally {
    await env.cleanup();
    await admin.app().delete();
  }
})().catch(error => {console.error(error); process.exitCode = 1;});
