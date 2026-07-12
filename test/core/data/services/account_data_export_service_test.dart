import 'dart:convert';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:stimmapp/core/constants/database_collections.dart';
import 'package:stimmapp/core/data/models/user_profile.dart';
import 'package:stimmapp/core/data/services/account_data_export_service.dart';
import 'package:stimmapp/core/data/services/database_service.dart';
import 'package:stimmapp/core/data/services/file_output/export_content_service.dart';
import 'package:stimmapp/core/data/services/file_output/export_file_writer.dart';

class _FakeFirebaseAuth extends Mock implements FirebaseAuth {
  _FakeFirebaseAuth(this._user);

  final User? _user;

  @override
  User? get currentUser => _user;
}

class _MockUserMetadata extends Mock implements UserMetadata {}

class _FakeUser implements User {
  _FakeUser({required this.metadata});

  @override
  String get uid => 'owner';

  @override
  String? get email => 'owner@example.com';

  @override
  String? get displayName => 'Owner';

  @override
  String? get phoneNumber => null;

  @override
  String? get photoURL => null;

  @override
  bool get emailVerified => true;

  @override
  bool get isAnonymous => false;

  @override
  final UserMetadata metadata;

  @override
  List<UserInfo> get providerData => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _CapturingExportFileWriter extends ExportFileWriter {
  _CapturingExportFileWriter(FakeFirebaseFirestore firestore)
    : super(DatabaseService(firestore));

  String? content;

  @override
  Future<String> save(
    String baseName,
    String content,
    ExportContentService contentService,
  ) async {
    this.content = content;
    return '/tmp/$baseName.json';
  }
}

void main() {
  test(
    'account export excludes other users participation data on own publications',
    () async {
      final firestore = FakeFirebaseFirestore();
      final metadata = _MockUserMetadata();
      final user = _FakeUser(metadata: metadata);
      final auth = _FakeFirebaseAuth(user);
      final writer = _CapturingExportFileWriter(firestore);

      when(metadata.creationTime).thenReturn(DateTime.utc(2026, 1, 1));
      when(metadata.lastSignInTime).thenReturn(DateTime.utc(2026, 1, 2));

      await firestore
          .collection(DatabaseCollections.users)
          .doc('owner')
          .set(
            const UserProfile(
              uid: 'owner',
              email: 'owner@example.com',
              displayName: 'Owner',
            ).toJson(),
          );
      await firestore.collection(DatabaseCollections.petitions).doc('p1').set({
        'title': 'Owner petition',
        'createdBy': 'owner',
      });
      await firestore
          .collection(DatabaseCollections.petitions)
          .doc('p1')
          .collection('signatures')
          .doc('other-user')
          .set({'uid': 'other-user', 'reason': 'private reason'});
      await firestore.collection(DatabaseCollections.polls).doc('poll1').set({
        'title': 'Owner poll',
        'createdBy': 'owner',
      });
      await firestore
          .collection(DatabaseCollections.polls)
          .doc('poll1')
          .collection(DatabaseCollections.votes)
          .doc('other-user')
          .set({'uid': 'other-user', 'optionId': 'yes'});
      await firestore.collection(DatabaseCollections.surveys).doc('s1').set({
        'title': 'Owner survey',
        'createdBy': 'owner',
      });
      await firestore
          .collection(DatabaseCollections.surveys)
          .doc('s1')
          .collection(DatabaseCollections.responses)
          .doc('other-user')
          .set({
            'uid': 'other-user',
            'answers': {'q1': 'yes'},
          });
      await firestore
          .collection(DatabaseCollections.users)
          .doc('owner')
          .collection('signedPetitions')
          .doc('own-signature')
          .set({'petitionId': 'own-signature'});

      await AccountDataExportService(
        firestore: firestore,
        auth: auth,
        writer: writer,
      ).saveCurrentUserData();

      final exported = jsonDecode(writer.content!) as Map<String, dynamic>;
      final encoded = writer.content!;

      expect(exported['createdPublications']['petitions'], hasLength(1));
      expect(exported['participation']['signedPetitions'], hasLength(1));
      expect(encoded, isNot(contains('private reason')));
      expect(encoded, isNot(contains('optionId')));
      expect(encoded, isNot(contains('answers')));
      expect(
        exported['scope'],
        contains('Does not include other users signatures'),
      );
    },
  );
}
