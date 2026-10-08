const {initializeTestEnvironment, assertSucceeds, assertFails} = require('@firebase/rules-unit-testing');
const {doc, setDoc, getDoc, deleteDoc} = require('firebase/firestore');

(async () => {
  const env = await initializeTestEnvironment({projectId: 'demo-stimmapp-pictures'});
  try {
    await env.withSecurityRulesDisabled(async ctx => {
      const db = ctx.firestore();
      for (const id of ['owner', 'stranger', 'guest', 'admin']) {
        await setDoc(doc(db, `petitions/${id}`), {
          title: 'Unfinished petition', createdBy: 'alice', signatureCount: 0,
        });
      }
    });
    const alice = env.authenticatedContext('alice', {email: 'alice@example.com'}).firestore();
    const bob = env.authenticatedContext('bob', {email: 'bob@example.com'}).firestore();
    const guest = env.unauthenticatedContext().firestore();
    const admin = env.authenticatedContext('service', {email: 'service@trainvent.com'}).firestore();
    await assertSucceeds(deleteDoc(doc(alice, 'petitions/owner')));
    if ((await getDoc(doc(alice, 'petitions/owner'))).exists()) throw new Error('Petition still exists');
    await assertFails(deleteDoc(doc(bob, 'petitions/stranger')));
    await assertFails(deleteDoc(doc(guest, 'petitions/guest')));
    await assertSucceeds(deleteDoc(doc(admin, 'petitions/admin')));
    console.log('Petition deletion rules passed: owner and admin allowed, strangers and guests denied.');
  } finally {
    await env.cleanup();
  }
})().catch(error => {console.error(error); process.exitCode = 1;});
