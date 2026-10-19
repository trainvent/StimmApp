import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stimmapp/app/widgets/buttons/sign_action_button.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:stimmapp/core/providers/auth_provider.dart';
import 'package:stimmapp/core/providers/app_preferences_provider.dart';
import 'package:stimmapp/core/providers/deferred_submission_provider.dart';
import 'package:stimmapp/generated/l10n.dart';
import 'package:stimmapp/l10n/app_localizations.dart';

class _User implements User {
  @override
  String get uid => 'signer';
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Auth extends AuthService {
  @override
  User get currentUser => _User();
}

void main() {
  for (final dismissal in ['outside', 'escape', 'back', 'skip', 'submit']) {
    testWidgets('signing dialog: $dismissal', (tester) async {
      final container = ProviderContainer(
        overrides: [authServiceProvider.overrideWithValue(_Auth())],
      );
      addTearDown(container.dispose);
      container.read(showPetitionReasonProvider.notifier).initialize(true);
      final submittedReasons = <String?>[];
      final participants = Stream.value(<String>{});
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: const [
              S.delegate,
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en')],
            home: Scaffold(
              body: SignActionButton(
                submissionId: 'petition:test',
                label: 'Sign',
                participantIdsStream: participants,
                askForReason: true,
                onAction: ({String? reason}) async =>
                    submittedReasons.add(reason),
                successMessage: 'Signed',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'My reason');
      switch (dismissal) {
        case 'outside':
          await tester.tapAt(const Offset(5, 5));
        case 'escape':
          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        case 'back':
          final context = tester.element(find.byType(AlertDialog));
          Navigator.of(context).pop();
        case 'skip':
          await tester.tap(find.text('Skip'));
        case 'submit':
          await tester.tap(find.text('Submit'));
      }
      // Avoid settling the animated undo countdown.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      final shouldSign = dismissal == 'skip' || dismissal == 'submit';
      expect(container.read(deferredSubmissionProvider).isNotEmpty, shouldSign);
      await tester.pump(const Duration(seconds: 6));
      expect(
        submittedReasons,
        shouldSign ? [dismissal == 'submit' ? 'My reason' : null] : isEmpty,
      );
    });
  }
}
