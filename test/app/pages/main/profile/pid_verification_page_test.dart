import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stimmapp/app/pages/main/profile/pid_verification_page.dart';
import 'package:stimmapp/core/data/services/pid_verification_service.dart';
import 'package:stimmapp/core/providers/auth_provider.dart';
import 'package:stimmapp/l10n/app_localizations.dart';

class _User extends Fake implements User {
  @override
  String get uid => 'owner';
}

class _Service extends Fake implements PidVerificationService {
  Future<PidVerificationStatusResponse> Function() status = () async =>
      const PidVerificationStatusResponse(
        status: 'verified',
        claims: {},
        normalizedClaims: {},
      );
  Object? acceptanceError;
  int checks = 0;
  int cancellations = 0;

  @override
  Future<PidResumableSession?> getResumableSession() async =>
      const PidResumableSession(
        sessionId: 'session',
        status: 'pending',
        mode: 'registration',
        purpose: 'Server English must not be displayed',
        expiresAt: '2027-01-01T12:00:00Z',
      );
  @override
  Future<PidVerificationStatusResponse> getStatus(String id) {
    checks++;
    return status();
  }

  @override
  Future<void> acceptVerifiedCredentials(String id) async {
    if (acceptanceError != null) throw acceptanceError!;
  }

  @override
  Future<String> cancelSession(String id) async {
    cancellations++;
    return 'cancelled';
  }
}

Future<void> _showPage(
  WidgetTester tester,
  _Service service, {
  String language = 'de',
}) async {
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentUserProvider.overrideWithValue(_User()),
        userProfileProvider.overrideWith((ref) => Stream.value(null)),
        pidVerificationServiceProvider.overrideWithValue(service),
      ],
      child: MaterialApp(
        locale: Locale(language),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const PidVerificationPage(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets(
    'waiting for the wallet offers recovery without claiming failure',
    (tester) async {
      final service = _Service()
        ..status = () async => const PidVerificationStatusResponse(
          status: 'pending',
          claims: {},
          normalizedClaims: {},
        );
      await _showPage(tester, service, language: 'en');
      for (var attempt = 0; attempt < 11; attempt++) {
        await tester.pump(const Duration(seconds: 1));
      }
      expect(service.checks, 10);
      expect(find.textContaining('No result yet.'), findsOneWidget);
      expect(
        find.textContaining('This verification has expired.'),
        findsNothing,
      );
      expect(find.text('Cancel this request'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('save timeout can recover an already accepted result', (
    tester,
  ) async {
    final service = _Service()
      ..acceptanceError = const PidVerificationException(
        'timeout',
        code: 'timeout',
      );
    await _showPage(tester, service, language: 'en');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Confirm verified identity'));
    await tester.tap(find.text('Confirm verified identity'));
    await tester.pumpAndSettle();
    service.status = () async => const PidVerificationStatusResponse(
      status: 'accepted',
      claims: {},
      normalizedClaims: {},
    );
    await tester.ensureVisible(find.text('Check status'));
    await tester.tap(find.text('Check status'));
    await tester.pumpAndSettle();
    expect(find.text('Identity verified and saved'), findsOneWidget);
    expect(find.text('Confirm verified identity'), findsNothing);
    expect(find.textContaining('The connection timed out.'), findsNothing);
  });

  testWidgets('German review is localized and cancellation closes it', (
    tester,
  ) async {
    final service = _Service();
    await _showPage(tester, service);
    await tester.pumpAndSettle();
    expect(find.text('Identität bestätigt – Angaben prüfen'), findsOneWidget);
    expect(find.text('Server English must not be displayed'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Diese Anfrage abbrechen'));
    await tester.tap(find.text('Diese Anfrage abbrechen'));
    await tester.pumpAndSettle();
    expect(service.cancellations, 1);
    expect(find.textContaining('Verifizierung abgebrochen.'), findsWidgets);
    expect(find.text('Bestätigte Identität übernehmen'), findsNothing);
    expect(find.text('Neue Anfrage starten'), findsOneWidget);
  });

  testWidgets(
    'a timeout keeps the session and allows a successful status retry',
    (tester) async {
      final service = _Service()
        ..status = () async => throw const PidVerificationException(
          'raw server error',
          code: 'timeout',
        );
      await _showPage(tester, service);
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Die Verbindung hat zu lange gedauert.'),
        findsOneWidget,
      );
      expect(find.text('raw server error'), findsNothing);
      service.status = () async => const PidVerificationStatusResponse(
        status: 'verified',
        claims: {},
        normalizedClaims: {},
      );
      await tester.ensureVisible(find.text('Status prüfen'));
      await tester.tap(find.text('Status prüfen'));
      await tester.pumpAndSettle();
      expect(service.checks, 2);
      expect(
        find.textContaining('Die Verbindung hat zu lange gedauert.'),
        findsNothing,
      );
      expect(find.text('Identität bestätigt – Angaben prüfen'), findsOneWidget);
    },
  );

  testWidgets('expiry while saving replaces the review with a restart action', (
    tester,
  ) async {
    final service = _Service()
      ..acceptanceError = const PidVerificationException(
        'expired',
        code: 'expired',
      );
    await _showPage(tester, service, language: 'en');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Confirm verified identity'));
    await tester.tap(find.text('Confirm verified identity'));
    await tester.pumpAndSettle();
    expect(find.textContaining('This verification has expired.'), findsWidgets);
    expect(find.text('Confirm verified identity'), findsNothing);
    expect(find.text('Start a new request'), findsOneWidget);
  });

  testWidgets('a late wallet status cannot reopen a cancelled review', (
    tester,
  ) async {
    final pending = Completer<PidVerificationStatusResponse>();
    final service = _Service()..status = () => pending.future;
    await _showPage(tester, service);
    await tester.ensureVisible(find.text('Diese Anfrage abbrechen'));
    await tester.tap(find.text('Diese Anfrage abbrechen'));
    await tester.pump();
    pending.complete(
      const PidVerificationStatusResponse(
        status: 'verified',
        claims: {},
        normalizedClaims: {},
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Verifizierung abgebrochen.'), findsWidgets);
    expect(find.text('Bestätigte Identität übernehmen'), findsNothing);
  });
}
