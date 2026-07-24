import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stimmapp/app/pages/main/profile/list/running_forms_page.dart';
import 'package:stimmapp/core/constants/internal_constants.dart';
import 'package:stimmapp/core/data/di/service_locator.dart';
import 'package:stimmapp/core/data/models/petition.dart';
import 'package:stimmapp/core/data/models/poll.dart';
import 'package:stimmapp/core/data/models/survey.dart';
import 'package:stimmapp/core/data/repositories/petition_repository.dart';
import 'package:stimmapp/core/data/repositories/poll_repository.dart';
import 'package:stimmapp/core/data/repositories/survey_repository.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:stimmapp/generated/l10n.dart';
import 'package:stimmapp/l10n/app_localizations.dart';

class _FakeUser implements User {
  const _FakeUser(this.uid);

  @override
  final String uid;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAuthService extends AuthService {
  _FakeAuthService(this._user);

  final User? _user;

  @override
  User? get currentUser => _user;
}

Widget _testApp(Widget child) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: const [
      S.delegate,
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en')],
    home: child,
  );
}

void main() {
  testWidgets('creator cannot delete running forms after participation', (
    tester,
  ) async {
    final firestore = FakeFirebaseFirestore();
    locator.setDatabaseForTest(firestore);

    final petitionId = await PetitionRepository.create().createPetition(
      Petition(
        id: 'petition-1',
        title: 'Signed petition',
        description: 'Has one signature',
        tags: const [],
        signatureCount: 1,
        createdBy: 'creator',
        createdAt: DateTime(2026, 1, 1),
        expiresAt: DateTime.now().add(const Duration(days: 1)),
        status: IConst.active,
      ),
    );
    final pollId = await PollRepository.create().createPoll(
      Poll(
        id: 'poll-1',
        title: 'Voted poll',
        description: 'Has one vote',
        tags: const [],
        options: const [
          PollOption(id: 'yes', label: 'Yes'),
          PollOption(id: 'no', label: 'No'),
        ],
        votes: const {'yes': 1, 'no': 0},
        createdBy: 'creator',
        createdAt: DateTime(2026, 1, 2),
        expiresAt: DateTime.now().add(const Duration(days: 1)),
        status: IConst.active,
      ),
    );
    final surveyId = await SurveyRepository.create().createSurvey(
      Survey(
        id: 'survey-1',
        title: 'Answered survey',
        description: 'Has one response',
        tags: const [],
        questions: const [
          SurveyQuestion(
            id: 'q1',
            title: 'Question',
            options: [
              SurveyOption(id: 'yes', label: 'Yes'),
              SurveyOption(id: 'no', label: 'No'),
            ],
          ),
        ],
        questionVotes: const {
          'q1': {'yes': 1, 'no': 0},
        },
        responseCount: 1,
        createdBy: 'creator',
        createdAt: DateTime(2026, 1, 3),
        expiresAt: DateTime.now().add(const Duration(days: 1)),
        status: IConst.active,
      ),
    );

    await tester.pumpWidget(
      _testApp(
        RunningFormsPage(auth: _FakeAuthService(const _FakeUser('creator'))),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Signed petition'), findsOneWidget);
    expect(find.byIcon(Icons.delete), findsNothing);

    await tester.tap(find.text('Polls'));
    await tester.pumpAndSettle();
    expect(find.text('Voted poll'), findsOneWidget);
    expect(find.byIcon(Icons.delete), findsNothing);

    await tester.tap(find.text('Surveys'));
    await tester.pumpAndSettle();
    expect(find.text('Answered survey'), findsOneWidget);
    expect(find.byIcon(Icons.delete), findsNothing);

    expect(await PetitionRepository.create().get(petitionId), isNotNull);
    expect(await PollRepository.create().get(pollId), isNotNull);
    expect(await SurveyRepository.create().get(surveyId), isNotNull);
  });
}
