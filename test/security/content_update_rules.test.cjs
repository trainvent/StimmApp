const {initializeTestEnvironment, assertSucceeds, assertFails} = require('@firebase/rules-unit-testing');
const {doc, setDoc, updateDoc, writeBatch, increment} = require('firebase/firestore');

(async () => {
  const env = await initializeTestEnvironment({projectId: 'demo-stimmapp-pictures'});
  try {
    await env.withSecurityRulesDisabled(async ctx => {
      for (const collection of ['petitions', 'polls']) {
        await setDoc(doc(ctx.firestore(), `${collection}/protected`), {
          createdBy: 'alice', title: 'Original', status: 'active',
          scopeType: 'global', scopeKey: 'global',
          ...(collection === 'petitions' ? {signatureCount: 0} : {votes: {yes: 0, no: 0}}),
        });
      }
    });
    const alice = env.authenticatedContext('alice', {email: 'alice@example.com'}).firestore();
    const bob = env.authenticatedContext('bob', {email: 'bob@example.com'}).firestore();
    const guest = env.unauthenticatedContext().firestore();
    const admin = env.authenticatedContext('service', {email: 'service@trainvent.com'}).firestore();
    for (const collection of ['petitions', 'polls']) {
      const path = `${collection}/protected`;
      const totals = collection === 'petitions' ? {signatureCount: 999} : {'votes.yes': 999};
      for (const db of [bob, guest]) {
        for (const change of [{title: 'Tampered'}, {status: 'closed'}, totals, {createdBy: 'bob'}]) {
          await assertFails(updateDoc(doc(db, path), change));
        }
      }
      await assertSucceeds(updateDoc(doc(alice, path), {title: 'Owner edit', status: 'closed'}));
      await assertFails(updateDoc(doc(alice, path), {createdBy: 'bob'}));
      await assertSucceeds(updateDoc(doc(admin, path), {title: 'Admin edit'}));
    }

    function signatureBatch({delta = 1, extra = {}, remove = false, uid = 'bob'} = {}) {
      const batch = writeBatch(bob);
      batch.update(doc(bob, 'petitions/protected'), {signatureCount: increment(delta), ...extra});
      const signature = doc(bob, `petitions/protected/signatures/${uid}`);
      if (remove) batch.delete(signature);
      else batch.set(signature, {uid, signedAt: new Date()});
      return batch.commit();
    }
    await assertFails(signatureBatch({delta: 10}));
    await assertFails(signatureBatch({extra: {title: 'Tampered'}}));
    await assertFails(signatureBatch({uid: 'alice'}));
    await assertFails(setDoc(doc(bob, 'petitions/protected/signatures/bob'), {uid: 'bob'}));
    await assertSucceeds(signatureBatch());
    await assertFails(signatureBatch()); // Existing signature cannot inflate count.
    await assertFails(signatureBatch({delta: -2, remove: true}));
    await assertSucceeds(signatureBatch({delta: -1, remove: true}));
    await assertFails(signatureBatch({delta: -1, remove: true}));

    function voteBatch({optionId = 'yes', counts = {'votes.yes': increment(1)}, extra = {}, remove = false, uid = 'bob'} = {}) {
      const batch = writeBatch(bob);
      batch.update(doc(bob, 'polls/protected'), {...counts, ...extra});
      const vote = doc(bob, `polls/protected/votes/${uid}`);
      if (remove) batch.delete(vote);
      else batch.set(vote, {uid, optionId, votedAt: new Date()});
      return batch.commit();
    }
    await assertFails(voteBatch({counts: {'votes.yes': increment(10)}}));
    await assertFails(voteBatch({counts: {'votes.yes': increment(1), 'votes.no': increment(1)}}));
    await assertFails(voteBatch({optionId: 'no'}));
    await assertFails(voteBatch({optionId: 'invented', counts: {'votes.invented': 1}}));
    await assertFails(voteBatch({extra: {status: 'active'}}));
    await assertFails(voteBatch({uid: 'alice'}));
    await assertFails(setDoc(doc(bob, 'polls/protected/votes/bob'), {uid: 'bob', optionId: 'yes'}));
    await assertSucceeds(voteBatch());
    await assertFails(updateDoc(doc(bob, 'polls/protected/votes/bob'), {optionId: 'no'}));
    await assertFails(voteBatch()); // Existing vote cannot inflate count.
    await assertFails(voteBatch({counts: {'votes.yes': increment(-2)}, remove: true}));
    await assertSucceeds(voteBatch({counts: {'votes.yes': increment(-1)}, remove: true}));
    await assertFails(voteBatch({counts: {'votes.yes': increment(-1)}, remove: true}));
    console.log('Content update rules passed: ownership, tampering, and participation counters.');
  } finally {
    await env.cleanup();
  }
})().catch(error => {console.error(error); process.exitCode = 1;});
