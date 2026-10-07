import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:stimmapp/core/data/models/poll.dart';

void main() {
  group('PollOption', () {
    final pollOption = PollOption(id: '1', label: 'Option 1');
    final pollOptionMap = {'id': '1', 'label': 'Option 1'};

    test('fromMap creates a PollOption object from a map', () {
      final result = PollOption.fromMap(pollOptionMap);
      expect(result.id, pollOption.id);
      expect(result.label, pollOption.label);
    });

    test('toMap returns a map from a PollOption object', () {
      final result = pollOption.toMap();
      expect(result, pollOptionMap);
    });
  });

  group('Poll', () {
    final timestamp = Timestamp.fromDate(DateTime(2023));
    final poll = Poll(
      id: 'poll1',
      title: 'Test Poll',
      description: 'This is a test poll.',
      tags: ['test', 'poll'],
      options: [PollOption(id: 'opt1', label: 'Option 1')],
      votes: {'opt1': 10},
      createdBy: 'user1',
      createdAt: timestamp.toDate(),
      expiresAt: timestamp.toDate(),
    );

    final pollFirestoreData = {
      'title': 'Test Poll',
      'description': 'This is a test poll.',
      'tags': ['test', 'poll'],
      'options': [
        {'id': 'opt1', 'label': 'Option 1'},
      ],
      'votes': {'opt1': 10},
      'createdBy': 'user1',
      'createdAt': timestamp,
      'expiresAt': timestamp,
      'openUntilClosed': false,
      'scheduledCloseAt': null,
      'status': 'active',
      'titleLowercase': 'test poll',
      'scopeType': 'global',
      'scopeUnionCode': null,
      'continentCode': null,
      'countryCode': null,
      'groupId': null,
      'groupName': null,
      'visibility': 'public',
      'stateOrRegion': null,
      'state': null,
      'town': null,
      'city': null,
      'scopeKey': 'global',
    };

    test(
      'fromFirestore creates a Poll object from a firestore snapshot',
      () async {
        final firestore = FakeFirebaseFirestore();
        final snap = await firestore.collection('polls').add(pollFirestoreData);

        final result = Poll.fromFirestore(await snap.get(), null);

        expect(result.id, isNotEmpty);
        expect(result.title, poll.title);
        expect(result.description, poll.description);
        expect(result.tags, poll.tags);
        expect(result.options.first.id, poll.options.first.id);
        expect(result.votes, poll.votes);
        expect(result.createdBy, poll.createdBy);
        // Timestamps are not identical, but should be close
        expect(result.createdAt.year, poll.createdAt.year);
        expect(result.expiresAt, poll.expiresAt);
        expect(result.countryCode, poll.countryCode);
        expect(result.groupId, poll.groupId);
        expect(result.groupName, poll.groupName);
        expect(result.visibility, poll.visibility);
      },
    );

    test('question text survives serialization and copying', () async {
      final withQuestion = poll.copyWith(
        questionTitle: 'How satisfied are you?',
      );
      final firestore = FakeFirebaseFirestore();
      final reference = await firestore
          .collection('polls')
          .add(Poll.toFirestore(withQuestion, null));
      final restored = Poll.fromFirestore(await reference.get(), null);
      expect(restored.questionTitle, 'How satisfied are you?');
      expect(
        restored.copyWith(title: 'New poll title').questionTitle,
        'How satisfied are you?',
      );
    });

    test('toFirestore returns a map from a Poll object', () {
      final result = Poll.toFirestore(poll, null);
      expect(result, pollFirestoreData);
    });
  });
}
