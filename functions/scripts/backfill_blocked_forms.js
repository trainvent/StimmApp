/* Publish safe placeholders for historical moderation removals.
 * Preview: node scripts/backfill_blocked_forms.js --project stimmapp-dev
 * Apply:   node scripts/backfill_blocked_forms.js --project stimmapp-dev --apply
 * Original content, identities, reports, and private messages are never copied.
 */
const admin = require('firebase-admin');

async function main() {
  const args = process.argv.slice(2);
  const projectIndex = args.indexOf('--project');
  const projectId = projectIndex < 0 ? null : args[projectIndex + 1];
  if (!projectId || projectId.startsWith('--')) {
    throw new Error('An explicit --project <projectId> is required.');
  }
  admin.initializeApp({projectId});
  const db = admin.firestore();
  const apply = args.includes('--apply');
  let cursor;
  let count = 0;
  while (true) {
    let query = db.collection('removedForms')
      .orderBy(admin.firestore.FieldPath.documentId()).limit(200);
    if (cursor) query = query.startAfter(cursor);
    const page = await query.get();
    if (page.empty) break;
    for (const doc of page.docs) {
      const data = doc.data();
      if (!['petition', 'poll'].includes(data.contentType)) continue;
      const target = db.collection('blockedForms').doc(doc.id);
      if ((await target.get()).exists) continue;
      if (apply) {
        // create() also protects reviewed summaries from concurrent overwrites.
        await target.create({
          contentType: data.contentType,
          removedAt: data.removedAt ?? null,
        });
      }
      count++;
    }
    cursor = page.docs[page.docs.length - 1];
  }
  console.log(`${apply ? 'Created' : 'Would create'} ${count} safe archive entries in ${projectId}.`);
}

main().catch((error) => {
  console.error(error.message);
  process.exitCode = 1;
});
