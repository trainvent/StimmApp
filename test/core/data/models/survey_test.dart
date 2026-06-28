import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stimmapp/core/data/models/survey.dart';

void main() {
  group('SurveyOption', () {
    const option = SurveyOption(id: 'opt1', label: 'Option 1');
    final optionMap = {'id': 'opt1', 'label': 'Option 1'};

    test('fromMap creates a SurveyOption', () {
      final result = SurveyOption.fromMap(optionMap);
      expect(result.id, option.id);
      expect(result.label, option.label);
    });

    test('toMap returns a map', () {
      expect(option.toMap(), optionMap);
    });
  });

  group('SurveyQuestion', () {
    const question = SurveyQuestion(
      id: 'q1',
      title: 'Question 1',
      options: [SurveyOption(id: 'opt1', label: 'Option 1')],
    );
    final questionMap = {
      'id': 'q1',
      'title': 'Question 1',
      'options': [
        {'id': 'opt1', 'label': 'Option 1'},
      ],
    };

    test('fromMap creates a SurveyQuestion', () {
      final result = SurveyQuestion.fromMap(questionMap);
      expect(result.id, question.id);
      expect(result.title, question.title);
      expect(result.options.first.id, question.options.first.id);
    });

    test('toMap returns a map', () {
      expect(question.toMap(), questionMap);
    });
  });

  group('Survey', () {
    final timestamp = Timestamp.fromDate(DateTime(2026));
    final survey = Survey(
      id: 'survey1',
      title: 'Test Survey',
      description: 'This is a test survey.',
      tags: ['survey'],
      questions: const [
        SurveyQuestion(
          id: 'q1',
          title: 'Question 1',
          options: [
            SurveyOption(id: 'opt1', label: 'Option 1'),
            SurveyOption(id: 'opt2', label: 'Option 2'),
          ],
        ),
      ],
      questionVotes: {
        'q1': {'opt1': 2, 'opt2': 1},
      },
      responseCount: 3,
      createdBy: 'user1',
      createdAt: timestamp.toDate(),
      expiresAt: timestamp.toDate(),
    );

    final firestoreData = {
      'title': 'Test Survey',
      'description': 'This is a test survey.',
      'tags': ['survey'],
      'questions': [
        {
          'id': 'q1',
          'title': 'Question 1',
          'options': [
            {'id': 'opt1', 'label': 'Option 1'},
            {'id': 'opt2', 'label': 'Option 2'},
          ],
        },
      ],
      'questionVotes': {
        'q1': {'opt1': 2, 'opt2': 1},
      },
      'responseCount': 3,
      'createdBy': 'user1',
      'createdAt': timestamp,
      'expiresAt': timestamp,
      'status': 'active',
      'titleLowercase': 'test survey',
      'scopeType': 'global',
      'continentCode': null,
      'countryCode': null,
      'groupId': null,
      'groupName': null,
      'visibility': 'public',
      'stateOrRegion': null,
      'state': null,
      'town': null,
      'city': null,
    };

    test('fromFirestore creates a Survey', () async {
      final firestore = FakeFirebaseFirestore();
      final doc = await firestore.collection('surveys').add(firestoreData);

      final result = Survey.fromFirestore(await doc.get(), null);

      expect(result.id, isNotEmpty);
      expect(result.title, survey.title);
      expect(result.description, survey.description);
      expect(result.tags, survey.tags);
      expect(result.questions.first.id, survey.questions.first.id);
      expect(result.questionVotes, survey.questionVotes);
      expect(result.responseCount, survey.responseCount);
      expect(result.participantCount, survey.responseCount);
    });

    test('toFirestore returns a map', () {
      expect(Survey.toFirestore(survey, null), firestoreData);
    });
  });
}
