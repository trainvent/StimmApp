import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stimmapp/app/pages/main/profile/list/finished_forms/form_export_page.dart';
import 'package:stimmapp/core/constants/internal_constants.dart';
import 'package:stimmapp/core/data/di/service_locator.dart';
import 'package:stimmapp/core/data/models/petition.dart';
import 'package:stimmapp/core/data/repositories/petition_repository.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:stimmapp/l10n/app_localizations.dart';

class _FakeUser implements User {
  const _FakeUser(this.uid);

  @override
  final String uid;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAuthService extends AuthService {
  _FakeAuthService(this.user);

  final User user;

  @override
  User get currentUser => user;
}

void main() {
  testWidgets('a scheduled form has a play button that resumes it', (
    tester,
  ) async {
    final firestore = FakeFirebaseFirestore();
    locator.setDatabaseForTest(firestore);
    final repository = PetitionRepository.create();
    final id = await repository.createPetition(
      Petition(
        id: '',
        title: 'Paused petition',
        description: 'A petition waiting for permanent closure.',
        tags: const [],
        signatureCount: 1,
        createdBy: 'creator',
        createdAt: DateTime(2026),
        expiresAt: DateTime(2026, 12, 31),
      ),
    );
    await repository.scheduleClose(id);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: FormExportPage(
          auth: _FakeAuthService(const _FakeUser('creator')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Paused petition'), findsOneWidget);
    expect(find.byIcon(Icons.play_circle_outline), findsOneWidget);

    await tester.tap(find.byIcon(Icons.play_circle_outline));
    await tester.pumpAndSettle();

    final resumed = await repository.get(id);
    expect(resumed!.status, IConst.active);
    expect(resumed.scheduledCloseAt, isNull);
    expect(find.text('Paused petition'), findsNothing);
  });
}
