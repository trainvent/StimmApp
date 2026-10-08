import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stimmapp/core/data/services/database_service.dart';
import 'package:stimmapp/core/data/services/participant_profile_loader.dart';
import 'package:stimmapp/core/data/repositories/user_repository.dart';

class PetitionComment {
  const PetitionComment({
    required this.signerId,
    required this.text,
    this.displayName,
    this.signedAt,
  });
  final String signerId;
  final String text;
  final String? displayName;
  final DateTime? signedAt;
}

class PetitionCommentRepository {
  PetitionCommentRepository(this.database);
  final DatabaseService database;

  Stream<List<PetitionComment>> watchComments(String petitionId) => database
      .instance
      .collection('petitions')
      .doc(petitionId)
      .collection('signatures')
      .snapshots()
      .asyncMap((snapshot) async {
        final docs = snapshot.docs
            .where(
              (doc) =>
                  doc.data()['reason'] is String &&
                  (doc.data()['reason'] as String).trim().isNotEmpty,
            )
            .toList();
        final profiles = await ParticipantProfileLoader(
          UserRepository(database),
        ).load(docs.map((doc) => doc.id));
        final comments = [
          for (var i = 0; i < docs.length; i++)
            PetitionComment(
              signerId: docs[i].id,
              text: (docs[i].data()['reason'] as String).trim(),
              displayName: profiles[i].displayName,
              signedAt: (docs[i].data()['signedAt'] as Timestamp?)?.toDate(),
            ),
        ];
        comments.sort((a, b) {
          final order = (b.signedAt?.millisecondsSinceEpoch ?? 0).compareTo(
            a.signedAt?.millisecondsSinceEpoch ?? 0,
          );
          return order != 0 ? order : a.signerId.compareTo(b.signerId);
        });
        return comments;
      });

  CollectionReference<Map<String, dynamic>> _likes(
    String petitionId,
    String signerId,
  ) => database.instance
      .collection('petitions')
      .doc(petitionId)
      .collection('signatures')
      .doc(signerId)
      .collection('commentLikes');

  Stream<Set<String>> watchLikes(String petitionId, String signerId) => _likes(
    petitionId,
    signerId,
  ).snapshots().map((snapshot) => snapshot.docs.map((doc) => doc.id).toSet());

  Future<void> setLiked(
    String petitionId,
    String signerId,
    String uid,
    bool liked,
  ) async {
    final like = _likes(petitionId, signerId).doc(uid);
    if (!liked) {
      await like.delete();
      return;
    }
    await database.instance.runTransaction((transaction) async {
      final signature = await transaction.get(like.parent.parent!);
      final petition = await transaction.get(
        database.instance.collection('petitions').doc(petitionId),
      );
      final existing = await transaction.get(like);
      final reason = signature.data()?['reason'];
      if (!petition.exists || reason is! String || reason.trim().isEmpty) {
        throw StateError('comment_missing');
      }
      if (!existing.exists) {
        transaction.set(like, {
          'uid': uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }
}
