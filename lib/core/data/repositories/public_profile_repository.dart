import 'package:stimmapp/core/data/services/participant_access_service.dart';
import 'package:stimmapp/core/data/models/public_profile.dart';
import 'package:stimmapp/core/data/services/database_service.dart';

class PublicProfileRepository {
  PublicProfileRepository(this.database, {ParticipantAccessService? access})
    : participantAccess = access ?? ParticipantAccessService();
  final ParticipantAccessService participantAccess;
  final DatabaseService database;

  Stream<PublicProfile?> watch(String uid) => participantAccess
      .watchPublicProfile(uid)
      .map(
        (profile) => profile == null
            ? null
            : PublicProfile(
                uid: uid,
                nickname: profile.displayName,
                imageUrl: profile.profilePictureUrl,
              ),
      );

  Future<List<PublicProfileForm>> publications(String uid) async {
    final sections = await Future.wait([
      for (final type in ['petition', 'poll', 'survey'])
        _publications(uid, type),
    ]);
    return sections.expand((section) => section).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<List<PublicProfileForm>> _publications(String uid, String type) async {
    final snapshot = await database.instance
        .collection('${type}s')
        .where('createdBy', isEqualTo: uid)
        .get();
    return snapshot.docs
        .where((doc) {
          final data = doc.data();
          return (data['visibility'] ?? 'public') == 'public' &&
              [
                'active',
                'closing',
                'closed',
              ].contains(data['status'] ?? 'active');
        })
        .map((doc) => PublicProfileForm.fromDocument(type, doc))
        .toList();
  }
}
