import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stimmapp/core/data/services/database_service.dart';
import 'package:stimmapp/core/data/services/participant_access_service.dart';
import 'package:stimmapp/core/data/models/user_profile.dart';

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
  PetitionCommentRepository(this.database, {ParticipantAccessService? access})
    : participantAccess = access ?? ParticipantAccessService();
  final ParticipantAccessService participantAccess;
  final DatabaseService database;

  Stream<List<PetitionComment>> watchComments(String petitionId) =>
      participantAccess.watch('petition', petitionId).map((entries) {
        final comments = <PetitionComment>[];
        for (final entry in entries) {
          final profile = entry['profile'] as UserProfile;
          final reason = entry['reason'];
          if (profile.signAnonymously ||
              reason is! String ||
              reason.trim().isEmpty) {
            continue;
          }
          comments.add(
            PetitionComment(
              signerId: profile.uid,
              text: reason.trim(),
              displayName: profile.displayName,
              signedAt: entry['signedAt'] == null
                  ? null
                  : DateTime.fromMillisecondsSinceEpoch(
                      (entry['signedAt'] as num).toInt(),
                    ),
            ),
          );
        }
        comments.sort(
          (a, b) => (b.signedAt?.millisecondsSinceEpoch ?? 0).compareTo(
            a.signedAt?.millisecondsSinceEpoch ?? 0,
          ),
        );
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
