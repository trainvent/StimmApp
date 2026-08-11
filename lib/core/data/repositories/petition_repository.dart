import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stimmapp/core/constants/app_limits.dart';
import 'package:stimmapp/core/data/models/petition.dart';
import 'package:stimmapp/core/data/models/user_profile.dart';
import 'package:stimmapp/core/data/repositories/user_repository.dart';
import 'package:stimmapp/core/data/di/service_locator.dart';
import 'package:stimmapp/core/data/services/database_service.dart';
import 'package:stimmapp/core/data/services/participant_profile_loader.dart';
import 'package:universal_io/io.dart';

class PetitionRepository {
  PetitionRepository(
    this._fs, {
    ParticipantProfileLoader? participantProfileLoader,
  }) : _participantProfileLoader =
           participantProfileLoader ??
           ParticipantProfileLoader(UserRepository(_fs));
  final DatabaseService _fs;
  final ParticipantProfileLoader _participantProfileLoader;

  static PetitionRepository create() =>
      PetitionRepository(locator.databaseService);

  CollectionReference<Petition> _col() => _fs.colRef<Petition>(
    'petitions',
    fromFirestore: Petition.fromFirestore,
    toFirestore: Petition.toFirestore,
  );

  Stream<List<Petition>> list({
    String? query,
    int? limit,
    required String status,
  }) {
    final q = (query ?? '').trim().toLowerCase();
    final queryRef = _col();

    Stream<List<Petition>> stream;
    if (q.isEmpty) {
      stream = _fs.watchCol<Petition>(
        queryRef.orderBy('createdAt', descending: true),
        limit: limit,
      );
    } else {
      stream = queryRef
          .where('titleLowercase', isGreaterThanOrEqualTo: q)
          .where('titleLowercase', isLessThan: '$q\uf8ff')
          .orderBy('titleLowercase')
          .snapshots()
          .map((s) => s.docs.map((d) => d.data()).toList());
    }

    return stream.map((petitions) {
      return petitions.where((p) => p.status == status).toList();
    });
  }

  Stream<Petition?> watch(String id) {
    final ref = _fs.docRef<Petition>(
      'petitions/$id',
      fromFirestore: Petition.fromFirestore,
      toFirestore: Petition.toFirestore,
    );
    return _fs.watchDoc(ref);
  }

  Future<Petition?> get(String id) async {
    final ref = _fs.docRef<Petition>(
      'petitions/$id',
      fromFirestore: Petition.fromFirestore,
      toFirestore: Petition.toFirestore,
    );
    final snap = await ref.get();
    return snap.data();
  }

  Future<String> createPetition(Petition petition) async {
    final normalizedTitle = petition.title.trim();
    final normalizedDescription = petition.description.trim();
    if (normalizedTitle.isEmpty ||
        normalizedTitle.length > AppLimits.maxTitleLength) {
      throw StateError('invalid_petition_title_length');
    }
    if (normalizedDescription.isEmpty ||
        normalizedDescription.length > AppLimits.maxDescriptionLength) {
      throw StateError('invalid_petition_description_length');
    }

    final normalizedPetition = petition.copyWith(
      title: normalizedTitle,
      description: normalizedDescription,
    );
    final docRef = await _col().add(normalizedPetition);
    return docRef.id;
  }

  Future<void> sign(String petitionId, String uid, {String? reason}) async {
    final db = _fs.instance;
    final petitionRef = db.collection('petitions').doc(petitionId);
    final userRef = db.collection('users').doc(uid);
    final signatureRef = petitionRef.collection('signatures').doc(uid);

    await db.runTransaction((txn) async {
      final sigSnap = await txn.get(signatureRef);
      if (sigSnap.exists) return; // idempotent
      txn.set(signatureRef, {
        'uid': uid,
        'signedAt': FieldValue.serverTimestamp(),
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      });
      txn.update(petitionRef, {'signatureCount': FieldValue.increment(1)});
      txn.set(userRef.collection('signedPetitions').doc(petitionId), {
        'petitionId': petitionId,
        'signedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Stream<List<Map<String, dynamic>>> watchSignatures(String petitionId) {
    return _fs.instance
        .collection('petitions')
        .doc(petitionId)
        .collection('signatures')
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  Stream<List<UserProfile>> watchParticipants(String petitionId) {
    return watchParticipantIds(
      petitionId,
    ).asyncMap(_participantProfileLoader.load);
  }

  Stream<Set<String>> watchParticipantIds(String petitionId) {
    return _fs.instance
        .collection('petitions')
        .doc(petitionId)
        .collection('signatures')
        .snapshots()
        .map((snap) => snap.docs.map((doc) => doc.id).toSet());
  }

  // Fetch participants once (used by CSV export)
  Future<List<Map<String, dynamic>>> getParticipantsWithSignaturesOnce(
    String petitionId,
  ) async {
    final snap = await _fs.instance
        .collection('petitions')
        .doc(petitionId)
        .collection('signatures')
        .get();

    if (snap.docs.isEmpty) return [];

    final profiles = await _participantProfileLoader.load(
      snap.docs.map((doc) => doc.id),
    );
    return [
      for (var index = 0; index < snap.docs.length; index++)
        {
          'profile': profiles[index],
          'reason': snap.docs[index].data()['reason'],
        },
    ];
  }

  // Fetch participants once (used by CSV export)
  Future<List<UserProfile>> getParticipantsOnce(String petitionId) async {
    final snap = await _fs.instance
        .collection('petitions')
        .doc(petitionId)
        .collection('signatures')
        .get();
    final uids = snap.docs.map((d) => d.id).toList();
    if (uids.isEmpty) return [];
    return _participantProfileLoader.load(uids);
  }

  // Remove all signatures by a user and decrement petition counts (used by user deletion)
  Future<void> removeSignaturesByUser(String uid) async {
    final db = _fs.instance;
    final signedPetitionsSnap = await db
        .collection('users')
        .doc(uid)
        .collection('signedPetitions')
        .get();
    await db.runTransaction((txn) async {
      for (final doc in signedPetitionsSnap.docs) {
        final petitionId = doc.id;
        final petitionRef = db.collection('petitions').doc(petitionId);
        txn.update(petitionRef, {'signatureCount': FieldValue.increment(-1)});
        txn.delete(petitionRef.collection('signatures').doc(uid));
        txn.delete(
          db
              .collection('users')
              .doc(uid)
              .collection('signedPetitions')
              .doc(petitionId),
        );
      }
    });
  }

  // Close petitions created by a user
  Future<void> closePetitionsCreatedByUser(String uid) async {
    final batch = _fs.instance.batch();
    final createdPetitionsSnap = await _col()
        .where('createdBy', isEqualTo: uid)
        .get();
    for (final doc in createdPetitionsSnap.docs) {
      batch.update(doc.reference, {'status': 'closed'});
    }
    await batch.commit();
  }

  Future<void> close(String id) async {
    await _col().doc(id).update({'status': 'closed'});
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchSignedPetitions(String uid) {
    return _fs.instance
        .collection('users')
        .doc(uid)
        .collection('signedPetitions')
        .orderBy('signedAt', descending: true)
        .snapshots();
  }

  Stream<Set<String>> watchSignedPetitionIds(String uid) {
    return _fs.instance
        .collection('users')
        .doc(uid)
        .collection('signedPetitions')
        .snapshots()
        .map((snap) => snap.docs.map((doc) => doc.id).toSet());
  }

  Future<void> delete(String id) async {
    await _col().doc(id).delete();
  }

  // Upload title image for petition and set imageUrl on the petition document.
  Future<String> uploadTitleImage(String petitionId, File file) async {
    final storage = locator.storageService;
    final url = await storage.uploadPetitionTitleImage(petitionId, file);
    await _fs.instance.collection('petitions').doc(petitionId).update({
      'imageUrl': url,
    });
    return url;
  }

  // Delete title image for petition and clear imageUrl field.
  Future<void> deleteTitleImage(String petitionId) async {
    final storage = locator.storageService;
    await storage.deletePetitionTitleImage(petitionId);
    await _fs.instance.collection('petitions').doc(petitionId).update({
      'imageUrl': FieldValue.delete(),
    });
  }
}
