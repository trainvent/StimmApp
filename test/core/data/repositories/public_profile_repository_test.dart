import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stimmapp/core/data/repositories/public_profile_repository.dart';
import 'package:stimmapp/core/data/services/database_service.dart';

void main() {
  test(
    'profile publications include only public forms from the requested creator',
    () async {
      final db = FakeFirebaseFirestore();
      final repo = PublicProfileRepository(DatabaseService(db));
      final examples = [
        ('petitions', 'petition', 'author', 'public', 'active', 1),
        ('polls', 'poll', 'author', 'public', 'closed', 2),
        ('surveys', 'survey', 'author', 'public', 'active', 3),
        ('polls', 'private-poll', 'author', 'group', 'active', 4),
        ('surveys', 'private-survey', 'author', 'group', 'active', 4),
        ('petitions', 'other', 'someone-else', 'public', 'active', 4),
        ('polls', 'removed', 'author', 'public', 'removed', 4),
      ];
      for (final (collection, id, creator, visibility, status, day)
          in examples) {
        await db.collection(collection).doc(id).set({
          'title': id,
          'createdBy': creator,
          'visibility': visibility,
          'status': status,
          'createdAt': Timestamp.fromDate(DateTime(2026, 1, day)),
        });
      }
      final forms = await repo.publications('author');
      expect(forms.map((form) => form.id), ['survey', 'poll', 'petition']);
      expect(forms.first.route, '/survey/survey');
      expect(await repo.watch('missing').first, isNull);
      await db.collection('users').doc('author').set({
        'displayName': 'Nickname',
        'email': 'private@example.com',
      });
      expect((await repo.watch('author').first)!.nickname, 'Nickname');
    },
  );
}
