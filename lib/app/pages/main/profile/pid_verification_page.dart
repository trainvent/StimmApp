import 'package:stimmapp/app/pages/main/profile/profile_page.dart';
import 'package:stimmapp/app/pages/main/profile/pid_verification_navigation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:stimmapp/app/scaffolds/app_bar_scaffold.dart';
import 'package:stimmapp/app/widgets/loading_info.dart';
import 'package:stimmapp/core/constants/internal_constants.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';
import 'package:stimmapp/core/data/models/user_profile.dart';
import 'package:stimmapp/core/data/repositories/user_repository.dart';
import 'package:stimmapp/core/data/services/pid_verification_service.dart';
import 'package:stimmapp/core/data/services/tomtom_search_service.dart';
import 'package:stimmapp/core/providers/auth_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class PidVerificationPage extends ConsumerStatefulWidget {
  const PidVerificationPage({super.key, this.reverify = false});

  final bool reverify;

  @override
  ConsumerState<PidVerificationPage> createState() =>
      _PidVerificationPageState();
}

class _PidVerificationPageState extends ConsumerState<PidVerificationPage>
    with WidgetsBindingObserver {
  late final ProviderSubscription<User?> _currentUserSubscription;
  PidVerificationService get _service =>
      ref.read(pidVerificationServiceProvider);
  bool _isCancelling = false;
  bool _waitingForWallet = false;
  int _operation = 0;
  bool get _busy =>
      _isLoading ||
      _isRestoringSession ||
      _isAcceptingCredentials ||
      _isCancelling;
  bool get _closed => [
    'accepted',
    'cancelled',
    'expired',
    'failed',
  ].contains(_verificationStatus);
  bool _isLoading = false;
  bool _isRestoringSession = true;
  bool _hasRequestedSessionRestore = false;
  bool _isCheckingStatus = false;
  bool _isAcceptingCredentials = false;
  String? _authorizationRequest;
  String? _verificationSessionId;
  String? _verificationStatus;
  Map<String, String?> _verifiedClaims = const {};
  Map<String, String?> _normalizedVerifiedClaims = const {};
  String? _error;
  String? _mode;
  DateTime? _expiresAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    pidVerificationNavigation.walletReturns.addListener(_walletReturned);
    // A web wallet callback cold-loads the app. Firebase Auth can still be
    // restoring its persisted session when this page first appears, so wait
    // for a signed-in user instead of treating the transient null as final.
    _currentUserSubscription = ref.listenManual<User?>(currentUserProvider, (
      _,
      user,
    ) {
      if (user == null || _hasRequestedSessionRestore) return;
      _hasRequestedSessionRestore = true;
      _restoreResumableVerification();
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    pidVerificationNavigation.walletReturns.removeListener(_walletReturned);
    _currentUserSubscription.close();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _verificationSessionId != null &&
        !_busy &&
        !_closed) {
      _pollVerificationStatus();
    }
  }

  void _walletReturned() {
    if (!mounted ||
        ModalRoute.of(context)?.isCurrent != true ||
        _busy ||
        _closed) {
      return;
    }
    _pollVerificationStatus();
  }

  void _returnToStart() {
    _operation++;
    setState(() {
      _verificationSessionId = null;
      _verificationStatus = null;
      _authorizationRequest = null;
      _verifiedClaims = const {};
      _normalizedVerifiedClaims = const {};
      _expiresAt = null;
      _error = null;
      _waitingForWallet = false;
    });
  }

  void _returnToProfile() {
    _operation++;
    final navigator = Navigator.of(context);
    var foundProfile = false;
    navigator.popUntil((route) {
      foundProfile = route.settings.name == '/profile';
      return foundProfile || route.isFirst;
    });
    if (!foundProfile) {
      navigator.push<void>(
        MaterialPageRoute(
          settings: const RouteSettings(name: '/profile'),
          builder: (_) => const ProfilePage(),
        ),
      );
    }
  }

  Future<void> _restoreResumableVerification() async {
    setState(() {
      _isRestoringSession = true;
      _error = null;
    });
    try {
      final session = await _service.getResumableSession();
      if (!mounted) return;
      if (session == null || session.sessionId.isEmpty) {
        setState(() => _isRestoringSession = false);
        return;
      }
      setState(() {
        _isRestoringSession = false;
        _verificationSessionId = session.sessionId;
        _verificationStatus = session.status;
        _mode = session.mode;
        _expiresAt = DateTime.tryParse(session.expiresAt);
      });
      await _pollVerificationStatus();
    } on PidVerificationException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = _messageFor(error, context.l10n.pidRestoreError);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = context.l10n.pidRestoreError;
      });
    } finally {
      if (mounted) setState(() => _isRestoringSession = false);
    }
  }

  String _messageFor(PidVerificationException error, String fallback) {
    if ([
      'expired',
      'cancelled',
      'failed',
      'session_closed',
      'session_not_found',
    ].contains(error.code)) {
      _verificationStatus = ['expired', 'cancelled'].contains(error.code)
          ? error.code
          : 'failed';
      _verifiedClaims = const {};
      _normalizedVerifiedClaims = const {};
    }
    return switch (error.code) {
      'unauthenticated' => context.l10n.pidSignedIn,
      'timeout' => context.l10n.pidTimeout,
      'expired' => context.l10n.pidExpired,
      'cancelled' => context.l10n.pidCancelled,
      'failed' => context.l10n.pidFailed,
      'session_not_found' || 'session_closed' => context.l10n.pidMissing,
      'invalid_claims' => context.l10n.pidInvalidClaims,
      _ => fallback,
    };
  }

  Future<void> _cancelVerification() async {
    final sessionId = _verificationSessionId;
    if (sessionId == null || _busy || _closed) return;
    _operation++;
    setState(() {
      _isCancelling = true;
      _error = null;
      _waitingForWallet = false;
    });
    try {
      final status = await _service.cancelSession(sessionId);
      if (!mounted) return;
      setState(() {
        _verificationStatus = status;
        _error = status == 'cancelled' ? context.l10n.pidCancelled : null;
        _verifiedClaims = const {};
        _normalizedVerifiedClaims = const {};
      });
    } on PidVerificationException catch (error) {
      if (mounted) {
        setState(
          () => _error = _messageFor(error, context.l10n.pidCancelError),
        );
      }
    } catch (_) {
      if (mounted) setState(() => _error = context.l10n.pidCancelError);
    } finally {
      if (mounted) setState(() => _isCancelling = false);
    }
  }

  Future<void> _startVerification() async {
    if (_busy || _isCheckingStatus) return;
    _operation++;
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      setState(() {
        _error = context.l10n.pidSignedIn;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _verificationStatus = null;
      _verificationSessionId = null;
      _authorizationRequest = null;
      _expiresAt = null;
      _waitingForWallet = false;
      _verifiedClaims = const {};
      _normalizedVerifiedClaims = const {};
    });

    try {
      final response = await _service.createRequest();
      if (!mounted) return;
      final expiresAt = DateTime.tryParse(response.expiresAt);
      setState(() {
        _authorizationRequest = response.authorizationRequest;
        _verificationSessionId = response.verificationSessionId;
        _mode = response.mode;
        _expiresAt = expiresAt;
      });
      await _openWallet(response.authorizationRequest);
    } on PidVerificationException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = _messageFor(error, context.l10n.pidStartError);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = context.l10n.pidStartError;
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _acceptVerifiedCredentials() async {
    final sessionId = _verificationSessionId;
    if (sessionId == null || _busy || _isCheckingStatus || _closed) return;
    setState(() {
      _isAcceptingCredentials = true;
      _error = null;
    });
    try {
      await _service.acceptVerifiedCredentials(sessionId);
      await _syncStateFromVerifiedAddress();
      if (!mounted) return;
      setState(() {
        _verificationStatus = 'accepted';
        _verifiedClaims = const {};
        _normalizedVerifiedClaims = const {};
        _authorizationRequest = null;
      });
    } on PidVerificationException catch (error) {
      if (mounted) {
        setState(() => _error = _messageFor(error, context.l10n.pidSaveError));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = context.l10n.pidSaveError);
      }
    } finally {
      if (mounted) setState(() => _isAcceptingCredentials = false);
    }
  }

  Future<void> _syncStateFromVerifiedAddress() async {
    final country = _claimForComparison('country')?.trim().toUpperCase();
    final address = _claimForComparison('formattedAddress')?.trim();
    final uid = ref.read(currentUserProvider)?.uid;
    if (country != 'DE' || address?.isNotEmpty != true || uid == null) return;

    try {
      final resolvedAddress = await TomTomSearchService(
        IConst.tomTomSearchApiKey,
      ).resolveAddress(address!, countries: const ['DE']);
      final state = resolvedAddress.state?.trim();
      if (resolvedAddress.countryCode?.toUpperCase() == 'DE' &&
          state?.isNotEmpty == true) {
        await UserRepository.create().update(uid, {'state': state});
      }
    } catch (error) {
      // State is derived profile metadata, not a PID-disclosed attribute.
      // Its enrichment must never turn an accepted PID into a failed flow.
      debugPrint('[PidVerificationPage] State enrichment failed: $error');
    }
  }

  String _normalizedIdentityValue(String? value) =>
      value
          ?.trim()
          .replaceAll(RegExp(r'\s+'), ' ')
          .toUpperCase()
          .replaceAll('ẞ', 'SS') ??
      '';

  String? _claimForComparison(String key) =>
      _normalizedVerifiedClaims[key] ?? _verifiedClaims[key];

  List<_PidFieldComparison> _comparisons(UserProfile? profile) {
    final profileBirthdate = profile?.dateOfBirth == null
        ? null
        : DateFormat('yyyy-MM-dd').format(profile!.dateOfBirth!);
    return [
          _PidFieldComparison(
            label: context.l10n.pidGivenName,
            currentValue: profile?.givenName,
            verifiedValue: _verifiedClaims['givenName'],
            normalizedVerifiedValue: _claimForComparison('givenName'),
          ),
          _PidFieldComparison(
            label: context.l10n.pidSurname,
            currentValue: profile?.surname,
            verifiedValue: _verifiedClaims['familyName'],
            normalizedVerifiedValue: _claimForComparison('familyName'),
          ),
          _PidFieldComparison(
            label: context.l10n.pidBirthdate,
            currentValue: profileBirthdate,
            verifiedValue: _verifiedClaims['birthdate'],
            normalizedVerifiedValue: _claimForComparison('birthdate'),
          ),
          _PidFieldComparison(
            label: context.l10n.pidAddress,
            currentValue: profile?.address,
            verifiedValue: _verifiedClaims['formattedAddress'],
            normalizedVerifiedValue: _claimForComparison('formattedAddress'),
            matchesOverride: _addressMatchesProfile(profile),
          ),
          _PidFieldComparison(
            label: context.l10n.pidRegion,
            currentValue: profile?.state,
            verifiedValue: _verifiedClaims['region'],
            normalizedVerifiedValue: _claimForComparison('region'),
          ),
          _PidFieldComparison(
            label: context.l10n.pidCountry,
            currentValue: profile?.countryCode,
            verifiedValue: _verifiedClaims['country'],
            normalizedVerifiedValue: _claimForComparison('country'),
          ),
        ]
        .where((comparison) => comparison.verifiedValue?.isNotEmpty == true)
        .toList();
  }

  bool _valuesMatch(_PidFieldComparison comparison) =>
      comparison.matchesOverride ??
      _normalizedIdentityValue(comparison.currentValue) ==
          _normalizedIdentityValue(comparison.normalizedVerifiedValue);

  String _normalizedAddressPart(String? value) =>
      _normalizedIdentityValue(value).replaceAll(RegExp(r'[\s,.;]+'), '');

  bool _addressMatchesProfile(UserProfile? profile) {
    final profileAddress = _normalizedAddressPart(profile?.address);
    final verifiedStreet = _normalizedAddressPart(
      _claimForComparison('streetAddress'),
    );
    final verifiedPostalCode = _normalizedAddressPart(
      _claimForComparison('postalCode'),
    );
    if (profileAddress.isEmpty ||
        verifiedStreet.isEmpty ||
        verifiedPostalCode.isEmpty) {
      return false;
    }

    final profileCountry = _normalizedIdentityValue(profile?.countryCode);
    final verifiedCountry = _normalizedIdentityValue(
      _claimForComparison('country'),
    );
    final countryMatches =
        profileCountry.isEmpty ||
        verifiedCountry.isEmpty ||
        profileCountry == verifiedCountry;

    // The PID and the address provider can use different localized city names
    // (for example, Koln/Köln versus Cologne). Street, postal code, and country
    // identify the same practical address without creating that false mismatch.
    return countryMatches &&
        profileAddress.contains(verifiedStreet) &&
        profileAddress.contains(verifiedPostalCode);
  }

  Future<void> _pollVerificationStatus() async {
    final sessionId = _verificationSessionId;
    if (sessionId == null || _isCheckingStatus || _closed) return;
    final operation = _operation;
    setState(() {
      _isCheckingStatus = true;
      _error = null;
      _waitingForWallet = false;
    });
    try {
      for (var attempt = 0; attempt < 10; attempt++) {
        if (!mounted || operation != _operation) return;
        final result = await _service.getStatus(sessionId);
        if (!mounted ||
            operation != _operation ||
            sessionId != _verificationSessionId) {
          return;
        }
        setState(() {
          _verificationStatus = result.status;
          _verifiedClaims = _closed ? const {} : result.claims;
          _normalizedVerifiedClaims = _closed
              ? const {}
              : result.normalizedClaims;
          if (result.status == 'failed') {
            _error = context.l10n.pidFailed;
          } else if (result.status == 'expired') {
            _error = context.l10n.pidExpired;
          } else if (result.status == 'cancelled') {
            _error = context.l10n.pidCancelled;
          }
        });
        if (result.isFinished) return;
        await Future<void>.delayed(const Duration(seconds: 1));
      }
      if (mounted && operation == _operation) {
        setState(() => _waitingForWallet = true);
      }
    } on PidVerificationException catch (error) {
      if (mounted && operation == _operation) {
        setState(
          () => _error = _messageFor(error, context.l10n.pidStatusError),
        );
      }
    } catch (_) {
      if (mounted) {
        if (operation == _operation) {
          setState(() => _error = context.l10n.pidStatusError);
        }
      }
    } finally {
      if (mounted) setState(() => _isCheckingStatus = false);
    }
  }

  Future<void> _openWallet([String? authorizationRequest]) async {
    final request = authorizationRequest ?? _authorizationRequest;
    if (request == null || request.isEmpty) return;

    final uri = Uri.tryParse(request);
    if (uri == null || uri.scheme != 'openid4vp') {
      if (mounted) {
        setState(() => _error = context.l10n.pidInvalidLink);
      }
      return;
    }

    var opened = false;
    try {
      opened = await launchUrl(
        uri,
        // A phone browser must be allowed to hand the custom scheme to the
        // installed wallet. Native builds continue to explicitly leave the
        // app for the wallet.
        mode: kIsWeb
            ? LaunchMode.platformDefault
            : LaunchMode.externalApplication,
      );
    } on PlatformException {
      opened = false;
    }
    if (!opened && mounted) {
      setState(() {
        _error = context.l10n.pidWalletMissing;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = ref.watch(userProfileProvider).asData?.value;
    final hasVerificationHistory =
        widget.reverify || userProfile?.hasIdentityVerificationHistory == true;
    final requestedMode =
        _mode ?? (hasVerificationHistory ? 'reverification' : 'registration');

    return PopScope(
      canPop: _verificationStatus != 'accepted',
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _verificationStatus == 'accepted') _returnToProfile();
      },
      child: AppBarScaffold(
        title: context.l10n.pidTitle,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.pidHeading,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          context.l10n.pidIntro,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        if (kIsWeb) ...[
                          const SizedBox(height: 8),
                          Text(
                            context.l10n.pidWebHint,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                        const SizedBox(height: 16),
                        Text(
                          requestedMode == 'reverification'
                              ? context.l10n.pidReverification
                              : context.l10n.pidRegistration,
                        ),
                        if (_expiresAt != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            context.l10n.pidExpiry(
                              DateFormat.yMd(
                                Localizations.localeOf(context).toLanguageTag(),
                              ).add_Hm().format(_expiresAt!.toLocal()),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (_waitingForWallet)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(context.l10n.pidWaitingHint),
                  ),
                if (_error != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(_error!),
                  )
                else if (_verificationSessionId == null)
                  const SizedBox.shrink(),
                if (_error != null && _verificationSessionId == null)
                  TextButton(
                    onPressed: _busy ? null : _restoreResumableVerification,
                    child: Text(context.l10n.pidRestore),
                  ),
                if (_verificationSessionId != null && !_closed)
                  TextButton(
                    onPressed: _busy ? null : _cancelVerification,
                    child: Text(
                      _isCancelling
                          ? context.l10n.pidCancelling
                          : context.l10n.pidCancel,
                    ),
                  ),
                if (_verificationSessionId != null) ...[
                  if (_verificationStatus != null) ...[
                    const SizedBox(height: 8),
                    Card(
                      color:
                          _verificationStatus == 'verified' ||
                              _verificationStatus == 'accepted'
                          ? Theme.of(context).colorScheme.primaryContainer
                          : null,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _verificationStatus == 'verified' ||
                                          _verificationStatus == 'accepted'
                                      ? Icons.verified_rounded
                                      : Icons.hourglass_top_rounded,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _verificationStatus == 'accepted'
                                        ? context.l10n.pidAccepted
                                        : _verificationStatus == 'verified'
                                        ? context.l10n.pidVerified
                                        : _verificationStatus == 'expired'
                                        ? context.l10n.pidExpired
                                        : _verificationStatus == 'cancelled'
                                        ? context.l10n.pidCancelled
                                        : _verificationStatus == 'failed'
                                        ? context.l10n.pidFailed
                                        : context.l10n.pidWaiting,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                ),
                              ],
                            ),
                            if (_verificationStatus == 'verified') ...[
                              if (_error != null)
                                TextButton(
                                  onPressed: _busy || _isCheckingStatus
                                      ? null
                                      : _pollVerificationStatus,
                                  child: Text(context.l10n.pidCheck),
                                ),
                              const SizedBox(height: 12),
                              Builder(
                                builder: (context) {
                                  final comparisons = _comparisons(userProfile);
                                  final hasMismatch = comparisons.any(
                                    (comparison) => !_valuesMatch(comparison),
                                  );
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        hasMismatch
                                            ? context.l10n.pidMismatch
                                            : context.l10n.pidMatch,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyLarge,
                                      ),
                                      const SizedBox(height: 8),
                                      ...comparisons.map((comparison) {
                                        final matches = _valuesMatch(
                                          comparison,
                                        );
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            top: 8,
                                          ),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Icon(
                                                matches
                                                    ? Icons.check_circle_outline
                                                    : Icons
                                                          .warning_amber_rounded,
                                                color: matches
                                                    ? Theme.of(
                                                        context,
                                                      ).colorScheme.primary
                                                    : Theme.of(
                                                        context,
                                                      ).colorScheme.error,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: _PidComparisonDetails(
                                                  comparison: comparison,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }),
                                      const SizedBox(height: 16),
                                      FilledButton(
                                        onPressed: _busy || _isCheckingStatus
                                            ? null
                                            : _acceptVerifiedCredentials,
                                        child: _isAcceptingCredentials
                                            ? LoadingInfo(
                                                text: hasMismatch
                                                    ? context.l10n.pidUseDetails
                                                    : context.l10n.pidConfirm,
                                                indicatorColor: Theme.of(
                                                  context,
                                                ).colorScheme.onPrimary,
                                                size: 18,
                                              )
                                            : Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(
                                                    Icons.person_pin_rounded,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Flexible(
                                                    child: Text(
                                                      hasMismatch
                                                          ? context
                                                                .l10n
                                                                .pidUseDetails
                                                          : context
                                                                .l10n
                                                                .pidConfirm,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                            if (_verificationStatus == 'accepted') ...[
                              const SizedBox(height: 12),
                              Text(context.l10n.pidSaved),
                              const SizedBox(height: 12),
                              FilledButton(
                                onPressed: _returnToStart,
                                child: Text(context.l10n.close),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (_verificationStatus != 'verified' &&
                      _verificationStatus != 'accepted') ...[
                    if (_authorizationRequest != null && !_closed) ...[
                      FilledButton.icon(
                        onPressed: _busy ? null : () => _openWallet(),
                        icon: const Icon(Icons.open_in_new_rounded),
                        label: Text(context.l10n.pidOpenWallet),
                      ),
                      const SizedBox(height: 12),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isCheckingStatus || _busy || _closed
                            ? null
                            : _pollVerificationStatus,
                        icon: const Icon(Icons.refresh_rounded),
                        label: _isCheckingStatus
                            ? LoadingInfo(
                                text: context.l10n.pidChecking,
                                indicatorColor: Theme.of(
                                  context,
                                ).colorScheme.primary,
                                size: 18,
                              )
                            : Text(context.l10n.pidCheck),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _busy || _isCheckingStatus
                                ? null
                                : _startVerification,
                            icon: const Icon(Icons.refresh),
                            label: Text(context.l10n.pidRestart),
                          ),
                        ),
                      ],
                    ),
                  ],
                ] else ...[
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isLoading || _isRestoringSession
                          ? null
                          : _startVerification,
                      child: _isLoading || _isRestoringSession
                          ? LoadingInfo(
                              text: _isRestoringSession
                                  ? context.l10n.pidRestoring
                                  : context.l10n.pidGenerating,
                              indicatorColor: Theme.of(
                                context,
                              ).colorScheme.onSurface,
                              size: 18,
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified_user_outlined),
                                SizedBox(width: 8),
                                Flexible(child: Text(context.l10n.pidStart)),
                              ],
                            ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PidComparisonDetails extends StatelessWidget {
  const _PidComparisonDetails({required this.comparison});

  final _PidFieldComparison comparison;

  @override
  Widget build(BuildContext context) {
    final profileValue = comparison.currentValue?.isNotEmpty == true
        ? comparison.currentValue!
        : context.l10n.pidNotProvided;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(comparison.label, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 2),
        Table(
          columnWidths: const {0: FixedColumnWidth(112), 1: FlexColumnWidth()},
          defaultVerticalAlignment: TableCellVerticalAlignment.top,
          children: [
            _valueRow(context.l10n.pidOriginal, comparison.verifiedValue ?? ''),
            _valueRow(
              context.l10n.pidCompared,
              comparison.normalizedVerifiedValue ?? '',
            ),
            _valueRow(context.l10n.pidProfile, profileValue),
          ],
        ),
      ],
    );
  }

  TableRow _valueRow(String label, String value) => TableRow(
    children: [
      Padding(
        padding: const EdgeInsets.only(right: 8, bottom: 2),
        child: Text(label),
      ),
      Padding(padding: const EdgeInsets.only(bottom: 2), child: Text(value)),
    ],
  );
}

class _PidFieldComparison {
  const _PidFieldComparison({
    required this.label,
    required this.currentValue,
    required this.verifiedValue,
    required this.normalizedVerifiedValue,
    this.matchesOverride,
  });

  final String label;
  final String? currentValue;
  final String? verifiedValue;
  final String? normalizedVerifiedValue;
  final bool? matchesOverride;
}
