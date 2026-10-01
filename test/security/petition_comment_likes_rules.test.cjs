const {initializeTestEnvironment, assertSucceeds, assertFails} = require('@firebase/rules-unit-testing');
const {doc, setDoc, getDoc, deleteDoc, updateDoc, serverTimestamp} = require('firebase/firestore');
(async () => {
  const env = await initializeTestEnvironment({projectId: 'demo-stimmapp-pictures'});
  try {
    await env.withSecurityRulesDisabled(async ctx => {
      const db = ctx.firestore();
      await setDoc(doc(db, 'petitions/p'), {title: 'Petition'});
      await setDoc(doc(db, 'petitions/p/signatures/author'), {reason: 'First line\nSecond line'});
      await setDoc(doc(db, 'petitions/p/signatures/empty'), {reason: '  '});
    });
    const db = uid => uid ? env.authenticatedContext(uid).firestore() : env.unauthenticatedContext().firestore();
    const like = (actor, owner = 'alice', signer = 'author') => doc(db(actor), `petitions/p/signatures/${signer}/commentLikes/${owner}`);
    const data = uid => ({uid, createdAt: serverTimestamp()});
    await assertSucceeds(setDoc(like('alice'), data('alice')));
    await assertSucceeds(getDoc(like(null)));
    await assertFails(setDoc(like('bob'), data('alice')));
    await assertFails(deleteDoc(like('bob')));
    await assertFails(updateDoc(like('alice'), {uid: 'bob'}));
    await assertFails(setDoc(like(null, 'guest'), data('guest')));
    await assertFails(setDoc(like('bob', 'bob', 'missing'), data('bob')));
    await assertFails(setDoc(like('bob', 'bob', 'empty'), data('bob')));
    await assertFails(setDoc(like('bob', 'bob'), {...data('bob'), count: 999}));
    await assertFails(setDoc(like('bob', 'bob'), {uid: 'bob', createdAt: new Date(0)}));
    await assertSucceeds(deleteDoc(like('alice')));
    await assertFails(updateDoc(doc(db('bob'), 'petitions/p/signatures/author'), {reason: 'Edited by stranger'}));
    await env.withSecurityRulesDisabled(ctx => deleteDoc(doc(ctx.firestore(), 'petitions/p')));
    await assertFails(setDoc(like('bob', 'bob'), data('bob')));
    console.log('Comment like rules passed: ownership, schema, timestamps, comment existence, and unlike.');
  } finally { await env.cleanup(); }
})().catch(error => {console.error(error); process.exitCode = 1;});
