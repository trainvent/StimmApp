import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stimmapp/core/constants/internal_constants.dart';
import 'package:stimmapp/core/data/di/service_locator.dart';
import 'package:stimmapp/core/data/models/survey.dart';
import 'package:stimmapp/core/data/repositories/survey_repository.dart';
import 'package:stimmapp/core/data/services/database_service.dart';

void main() {
  late SurveyRepository surveyRepository;
  late FakeFirebaseFirestore fakeFirebaseFirestore;
  late DatabaseService databaseService;

  setUp(() {
    fakeFirebaseFirestore = FakeFirebaseFirestore();
    databaseService = DatabaseService(fakeFirebaseFirestore);
    surveyRepository = SurveyRepository(databaseService);
    locator.setDatabaseForTest(fakeFirebaseFirestore);
  });

  group('SurveyRepository', () {
    final survey = Survey(
      id: 'survey1',
      title: 'Test Survey',
      description: 'A test survey description',
      tags: const [],
      questions: const [
        SurveyQuestion(
          id: 'q1',
          title: 'Question 1',
          options: [
            SurveyOption(id: 'q1-opt1', label: 'Option 1'),
            SurveyOption(id: 'q1-opt2', label: 'Option 2'),
          ],
        ),
        SurveyQuestion(
          id: 'q2',
          title: 'Question 2',
          options: [
            SurveyOption(id: 'q2-opt1', label: 'Option 1'),
            SurveyOption(id: 'q2-opt2', label: 'Option 2'),
          ],
        ),
      ],
      questionVotes: const {},
      createdBy: 'user1',
      createdAt: DateTime(2026),
      expiresAt: DateTime.now().add(const Duration(days: 1)),
      status: IConst.active,
    );

    test('createSurvey and watch work correctly', () async {
      final surveyId = await surveyRepository.createSurvey(survey);
      final stream = surveyRepository.watch(surveyId);

      expect(
        stream,
        emits(
          predicate<Survey?>(
            (item) =>
                item != null &&
                item.title == survey.title &&
                item.questionVotes['q1']?['q1-opt1'] == 0,
          ),
        ),
      );
    });

    test('list returns active surveys', () async {
      await surveyRepository.createSurvey(survey);
      final stream = surveyRepository.list(status: IConst.active);

      expect(
        stream,
        emits(
          predicate<List<Survey>>(
            (items) => items.isNotEmpty && items.first.title == survey.title,
          ),
        ),
      );
    });

    test(
      'submitResponse increments counts for every answered question',
      () async {
        final surveyId = await surveyRepository.createSurvey(survey);

        await surveyRepository.submitResponse(
          surveyId: surveyId,
          uid: 'user1',
          answers: {'q1': 'q1-opt1', 'q2': 'q2-opt2'},
        );

        final saved = await surveyRepository.get(surveyId);
        expect(saved, isNotNull);
        expect(saved!.responseCount, 1);
        expect(saved.questionVotes['q1']?['q1-opt1'], 1);
        expect(saved.questionVotes['q1']?['q1-opt2'], 0);
        expect(saved.questionVotes['q2']?['q2-opt1'], 0);
        expect(saved.questionVotes['q2']?['q2-opt2'], 1);

        final response = await fakeFirebaseFirestore
            .collection('surveys')
            .doc(surveyId)
            .collection('responses')
            .doc('user1')
            .get();
        expect(response.exists, isTrue);

        final completedSurvey = await fakeFirebaseFirestore
            .collection('users')
            .doc('user1')
            .collection('completedSurveys')
            .doc(surveyId)
            .get();
        expect(completedSurvey.exists, isTrue);
      },
    );

    test('a user can submit only once', () async {
      final surveyId = await surveyRepository.createSurvey(survey);

      await surveyRepository.submitResponse(
        surveyId: surveyId,
        uid: 'user1',
        answers: {'q1': 'q1-opt1', 'q2': 'q2-opt2'},
      );
      await surveyRepository.submitResponse(
        surveyId: surveyId,
        uid: 'user1',
        answers: {'q1': 'q1-opt2', 'q2': 'q2-opt1'},
      );

      final saved = await surveyRepository.get(surveyId);
      expect(saved, isNotNull);
      expect(saved!.responseCount, 1);
      expect(saved.questionVotes['q1']?['q1-opt1'], 1);
      expect(saved.questionVotes['q1']?['q1-opt2'], 0);
    });

    test('submitResponse rejects incomplete answers', () async {
      final surveyId = await surveyRepository.createSurvey(survey);

      expect(
        () => surveyRepository.submitResponse(
          surveyId: surveyId,
          uid: 'user1',
          answers: {'q1': 'q1-opt1'},
        ),
        throwsA(isA<StateError>()),
      );
    });

    test(
      'removeResponsesByUser decrements counts and deletes response history',
      () async {
        final surveyId = await surveyRepository.createSurvey(survey);
        await surveyRepository.submitResponse(
          surveyId: surveyId,
          uid: 'user1',
          answers: {'q1': 'q1-opt1', 'q2': 'q2-opt2'},
        );

        await surveyRepository.removeResponsesByUser('user1');

        final saved = await surveyRepository.get(surveyId);
        expect(saved, isNotNull);
        expect(saved!.responseCount, 0);
        expect(saved.questionVotes['q1']?['q1-opt1'], 0);
        expect(saved.questionVotes['q2']?['q2-opt2'], 0);

        final response = await fakeFirebaseFirestore
            .collection('surveys')
            .doc(surveyId)
            .collection('responses')
            .doc('user1')
            .get();
        expect(response.exists, isFalse);
      },
    );

    test('closeSurveysCreatedByUser closes matching surveys', () async {
      final surveyId = await surveyRepository.createSurvey(survey);

      await surveyRepository.closeSurveysCreatedByUser('user1');

      final saved = await surveyRepository.get(surveyId);
      expect(saved, isNotNull);
      expect(saved!.status, 'closed');
    });
  });
}
