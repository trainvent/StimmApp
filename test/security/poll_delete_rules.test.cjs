const {initializeTestEnvironment, assertSucceeds, assertFails} = require('@firebase/rules-unit-testing');
const {doc, setDoc, getDoc, deleteDoc} = require('firebase/firestore');

(async () => {
  const env = await initializeTestEnvironment({projectId: 'demo-stimmapp-pictures'});
  try {
    await env.withSecurityRulesDisabled(async ctx => {
      const db = ctx.firestore();
      for (const id of ['owner', 'stranger', 'guest', 'admin']) {
        await setDoc(doc(db, `polls/${id}`), {
          title: 'Unfinished poll', createdBy: 'alice', votes: {yes: 0, no: 0},
        });
      }
    });
    const alice = env.authenticatedContext('alice', {email: 'alice@example.com'}).firestore();
    const bob = env.authenticatedContext('bob', {email: 'bob@example.com'}).firestore();
    const guest = env.unauthenticatedContext().firestore();
    const admin = env.authenticatedContext('service', {email: 'service@trainvent.com'}).firestore();
    await assertSucceeds(deleteDoc(doc(alice, 'polls/owner')));
    if ((await getDoc(doc(alice, 'polls/owner'))).exists()) throw new Error('Poll still exists');
    await assertFails(deleteDoc(doc(bob, 'polls/stranger')));
    await assertFails(deleteDoc(doc(guest, 'polls/guest')));
    await assertSucceeds(deleteDoc(doc(admin, 'polls/admin')));
    console.log('Poll deletion rules passed: owner and admin allowed, strangers and guests denied.');
  } finally {
    await env.cleanup();
  }
})().catch(error => {console.error(error); process.exitCode = 1;});
