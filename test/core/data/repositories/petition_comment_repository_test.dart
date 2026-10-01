import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stimmapp/core/data/repositories/petition_comment_repository.dart';
import 'package:stimmapp/core/data/services/database_service.dart';

void main() {
  late FakeFirebaseFirestore db;
  late PetitionCommentRepository repo;
  setUp(() async {
    db = FakeFirebaseFirestore();
    repo = PetitionCommentRepository(DatabaseService(db));
    await db.doc('petitions/p').set({'title': 'Petition'});
    await db.doc('users/author').set({'displayName': 'Test author'});
    await db.doc('petitions/p/signatures/author').set({
      'reason': ' A better future ',
      'signedAt': Timestamp.fromDate(DateTime(2026)),
    });
  });
  test(
    'existing reasons become comments, empty signatures are omitted',
    () async {
      await db.doc('petitions/p/signatures/empty').set({'reason': '  '});
      await db.doc('petitions/p/signatures/noReason').set({'uid': 'noReason'});
      final comments = await repo.watchComments('p').first;
      expect(comments, hasLength(1));
      expect(comments.single.text, 'A better future');
      expect(comments.single.signerId, 'author');
      expect(comments.single.displayName, 'Test author');
    },
  );
  test(
    'likes are idempotent per account and can be removed independently',
    () async {
      await repo.setLiked('p', 'author', 'alice', true);
      await repo.setLiked('p', 'author', 'alice', true);
      await repo.setLiked('p', 'author', 'bob', true);
      expect(await repo.watchLikes('p', 'author').first, {'alice', 'bob'});
      await repo.setLiked('p', 'author', 'alice', false);
      expect(await repo.watchLikes('p', 'author').first, {'bob'});
      expect(
        (await db.doc('petitions/p/signatures/author').get()).data()!['reason'],
        ' A better future ',
      );
    },
  );
  test('cannot like a missing, empty, or deleted petition comment', () async {
    await expectLater(
      repo.setLiked('p', 'missing', 'alice', true),
      throwsStateError,
    );
    await db.doc('petitions/p/signatures/empty').set({'reason': '  '});
    await expectLater(
      repo.setLiked('p', 'empty', 'alice', true),
      throwsStateError,
    );
    await db.doc('petitions/p').delete();
    await expectLater(
      repo.setLiked('p', 'author', 'alice', true),
      throwsStateError,
    );
  });
}
