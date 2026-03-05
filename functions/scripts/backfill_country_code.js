const admin = require('firebase-admin');

function parseArgs(argv) {
  const args = {
    project: process.env.GCLOUD_PROJECT || process.env.GOOGLE_CLOUD_PROJECT || '',
    countryCode: 'DE',
    dryRun: true,
  };

  for (let i = 2; i < argv.length; i++) {
    const arg = argv[i];
    if (arg === '--project' || arg === '--projectId') {
      args.project = argv[++i] || '';
    } else if (arg === '--country' || arg === '--countryCode') {
      args.countryCode = (argv[++i] || 'DE').toUpperCase();
    } else if (arg === '--apply') {
      args.dryRun = false;
    } else if (arg === '--dry-run') {
      args.dryRun = true;
    }
  }

  return args;
}

async function backfillCollection({ db, collection, countryCode, dryRun }) {
  const pageSize = 500;
  const commitChunkSize = 350;

  let scanned = 0;
  let updated = 0;
  let lastDoc = null;
  let batch = db.batch();
  let pendingWrites = 0;

  while (true) {
    let query = db.collection(collection).orderBy(admin.firestore.FieldPath.documentId()).limit(pageSize);
    if (lastDoc) query = query.startAfter(lastDoc);

    const snap = await query.get();
    if (snap.empty) break;

    for (const doc of snap.docs) {
      scanned++;
      const raw = doc.get('countryCode');
      const normalized = typeof raw === 'string' ? raw.trim().toUpperCase() : '';
      const missing = raw == null || normalized.length === 0;
      if (!missing) continue;

      updated++;
      if (!dryRun) {
        batch.update(doc.ref, {
          countryCode,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        pendingWrites++;

        if (pendingWrites >= commitChunkSize) {
          await batch.commit();
          batch = db.batch();
          pendingWrites = 0;
        }
      }
    }

    lastDoc = snap.docs[snap.docs.length - 1];
    if (snap.size < pageSize) break;
  }

  if (!dryRun && pendingWrites > 0) {
    await batch.commit();
  }

  return { collection, scanned, updated };
}

async function main() {
  const { project, countryCode, dryRun } = parseArgs(process.argv);

  if (!project) {
    throw new Error('Missing --project <projectId> (example: stimmapp-f0141)');
  }

  if (!/^[A-Z]{2}$/.test(countryCode)) {
    throw new Error('countryCode must be a 2-letter ISO code, e.g. DE');
  }

  admin.initializeApp({ projectId: project });
  const db = admin.firestore();

  console.log(`[backfill_country_code] project=${project} countryCode=${countryCode} dryRun=${dryRun}`);

  const [petitions, polls] = await Promise.all([
    backfillCollection({ db, collection: 'petitions', countryCode, dryRun }),
    backfillCollection({ db, collection: 'polls', countryCode, dryRun }),
  ]);

  const totalScanned = petitions.scanned + polls.scanned;
  const totalUpdated = petitions.updated + polls.updated;

  console.log('[backfill_country_code] result:', {
    dryRun,
    countryCode,
    totalScanned,
    totalUpdated,
    collections: [petitions, polls],
  });

  await admin.app().delete();
}

main().catch((err) => {
  console.error('[backfill_country_code] failed:', err);
  process.exit(1);
});
