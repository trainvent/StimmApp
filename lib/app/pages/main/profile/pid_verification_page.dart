import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:stimmapp/app/scaffolds/app_bar_scaffold.dart';
import 'package:stimmapp/app/widgets/snackbar_utils.dart';
import 'package:stimmapp/core/constants/internal_constants.dart';
import 'package:stimmapp/core/data/models/user_profile.dart';
import 'package:stimmapp/core/data/repositories/user_repository.dart';
import 'package:stimmapp/core/data/services/pid_verification_service.dart';
import 'package:stimmapp/core/data/services/tomtom_search_service.dart';
import 'package:stimmapp/core/providers/auth_provider.dart';
import 'package:trainvent_general/trainvent_general.dart';
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
  bool _isLoading = false;
  bool _isRestoringSession = true;
  bool _isCheckingStatus = false;
  bool _isAcceptingCredentials = false;
  bool _acceptedCredentials = false;
  String? _authorizationRequest;
  String? _verificationSessionId;
  String? _verificationStatus;
  Map<String, String?> _verifiedClaims = const {};
  Map<String, String?> _normalizedVerifiedClaims = const {};
  String? _error;
  String? _purpose;
  String? _mode;
  DateTime? _expiresAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restoreResumableVerification();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _verificationSessionId != null) {
      _pollVerificationStatus();
    }
  }

  Future<void> _restoreResumableVerification() async {
    if (ref.read(currentUserProvider) == null) {
      if (mounted) setState(() => _isRestoringSession = false);
      return;
    }
    try {
      final session = await pidVerificationService.getResumableSession();
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
        _purpose = session.purpose;
        _expiresAt = DateTime.tryParse(session.expiresAt);
      });
      await _pollVerificationStatus();
    } on PidVerificationException catch (error) {
      if (!mounted) return;
      setState(() {
        _isRestoringSession = false;
        _error = error.message;
      });
    }
  }

  Future<void> _startVerification() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      setState(() {
        _error = 'You need to be signed in to verify your identity.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _verificationStatus = null;
      _verifiedClaims = const {};
      _normalizedVerifiedClaims = const {};
      _acceptedCredentials = false;
    });

    try {
      final response = await pidVerificationService.createRequest();
      if (!mounted) return;
      final expiresAt = DateTime.tryParse(response.expiresAt);
      setState(() {
        _authorizationRequest = response.authorizationRequest;
        _verificationSessionId = response.verificationSessionId;
        _purpose = response.purpose;
        _mode = response.mode;
        _expiresAt = expiresAt;
      });
      await _openWallet(response.authorizationRequest);
    } on PidVerificationException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _acceptVerifiedCredentials() async {
    final sessionId = _verificationSessionId;
    if (sessionId == null || _isAcceptingCredentials) return;
    setState(() {
      _isAcceptingCredentials = true;
      _error = null;
    });
    try {
      await pidVerificationService.acceptVerifiedCredentials(sessionId);
      await _syncStateFromVerifiedAddress();
      if (!mounted) return;
      setState(() {
        _acceptedCredentials = true;
        _verificationStatus = 'accepted';
      });
      showSuccessSnackBar('Your profile now uses the verified EUDI details.');
    } on PidVerificationException catch (error) {
      if (mounted) setState(() => _error = error.message);
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
            label: 'Given name',
            currentValue: profile?.givenName,
            verifiedValue: _verifiedClaims['givenName'],
            normalizedVerifiedValue: _claimForComparison('givenName'),
          ),
          _PidFieldComparison(
            label: 'Surname',
            currentValue: profile?.surname,
            verifiedValue: _verifiedClaims['familyName'],
            normalizedVerifiedValue: _claimForComparison('familyName'),
          ),
          _PidFieldComparison(
            label: 'Date of birth',
            currentValue: profileBirthdate,
            verifiedValue: _verifiedClaims['birthdate'],
            normalizedVerifiedValue: _claimForComparison('birthdate'),
          ),
          _PidFieldComparison(
            label: 'Living address',
            currentValue: profile?.address,
            verifiedValue: _verifiedClaims['formattedAddress'],
            normalizedVerifiedValue: _claimForComparison('formattedAddress'),
            matchesOverride: _addressMatchesProfile(profile),
          ),
          _PidFieldComparison(
            label: 'State or region',
            currentValue: profile?.state,
            verifiedValue: _verifiedClaims['region'],
            normalizedVerifiedValue: _claimForComparison('region'),
          ),
          _PidFieldComparison(
            label: 'Country',
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
    if (sessionId == null || _isCheckingStatus) return;
    _isCheckingStatus = true;
    if (mounted) setState(() => _verificationStatus = 'pending');
    try {
      for (var attempt = 0; attempt < 10; attempt++) {
        final result = await pidVerificationService.getStatus(sessionId);
        if (!mounted || sessionId != _verificationSessionId) return;
        setState(() {
          _verificationStatus = result.status;
          _verifiedClaims = result.claims;
          _normalizedVerifiedClaims = result.normalizedClaims;
          if (result.status == 'failed') {
            _error =
                result.error ?? 'The PID presentation could not be verified.';
          } else if (result.status == 'expired') {
            _error =
                'The PID verification request expired. Please create a new one.';
          } else if (result.status == 'accepted') {
            _acceptedCredentials = true;
          }
        });
        if (result.isFinished) return;
        await Future<void>.delayed(const Duration(seconds: 1));
      }
    } on PidVerificationException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      _isCheckingStatus = false;
    }
  }

  Future<void> _openWallet([String? authorizationRequest]) async {
    final request = authorizationRequest ?? _authorizationRequest;
    if (request == null || request.isEmpty) return;

    final uri = Uri.tryParse(request);
    if (uri == null || uri.scheme != 'openid4vp') {
      if (mounted) {
        setState(
          () => _error = 'The verifier returned an invalid wallet link.',
        );
      }
      return;
    }

    var opened = false;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on PlatformException {
      opened = false;
    }
    if (!opened && mounted) {
      setState(() {
        _error =
            'No app accepted the OpenID4VP request. Make sure the EUDI Wallet sandbox app is installed.';
      });
    }
  }

  Future<void> _copyRequest() async {
    if (_authorizationRequest == null || _authorizationRequest!.isEmpty) {
      return;
    }
    await Clipboard.setData(ClipboardData(text: _authorizationRequest!));
    if (mounted) {
      showSuccessSnackBar('OpenID4VP request copied to clipboard.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = ref.watch(userProfileProvider).asData?.value;
    final hasVerificationHistory =
        widget.reverify || userProfile?.hasIdentityVerificationHistory == true;
    final requestedMode =
        _mode ?? (hasVerificationHistory ? 'reverification' : 'registration');

    return AppBarScaffold(
      title: 'PID verification',
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
                        'Identity verification',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Creates a PID verification request and opens it in the EUDI Wallet sandbox app.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Mode: ${requestedMode == 'reverification' ? 'Re-verification' : 'Registration'}',
                      ),
                      if (_purpose != null) ...[
                        const SizedBox(height: 8),
                        Text('Purpose: $_purpose'),
                      ],
                      if (_expiresAt != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Expires: ${DateFormat('yyyy-MM-dd HH:mm').format(_expiresAt!)}',
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
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
                              Text(
                                _verificationStatus == 'accepted'
                                    ? 'PID verified and saved'
                                    : _verificationStatus == 'verified'
                                    ? 'PID verified — confirmation required'
                                    : 'Waiting for wallet response…',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                          if (_verificationStatus == 'verified') ...[
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
                                          ? 'Some verified details differ from your profile.'
                                          : 'Your verified details match your profile.',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyLarge,
                                    ),
                                    const SizedBox(height: 8),
                                    ...comparisons.map((comparison) {
                                      final matches = _valuesMatch(comparison);
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Icon(
                                              matches
                                                  ? Icons.check_circle_outline
                                                  : Icons.warning_amber_rounded,
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
                                    if (_acceptedCredentials)
                                      const Row(
                                        children: [
                                          Icon(Icons.check_circle_rounded),
                                          SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Verified EUDI details saved to your profile.',
                                            ),
                                          ),
                                        ],
                                      )
                                    else
                                      FilledButton.icon(
                                        onPressed: _isAcceptingCredentials
                                            ? null
                                            : _acceptVerifiedCredentials,
                                        icon: _isAcceptingCredentials
                                            ? SizedBox(
                                                width: 18,
                                                height: 18,
                                                child: TriangleLoadingIndicator(
                                                  size: 18,
                                                  showFill: false,
                                                  strokeColor: Theme.of(
                                                    context,
                                                  ).colorScheme.onPrimary,
                                                ),
                                              )
                                            : const Icon(
                                                Icons.person_pin_rounded,
                                              ),
                                        label: Text(
                                          hasMismatch
                                              ? 'Use verified EUDI details'
                                              : 'Confirm verified identity',
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                          ],
                          if (_verificationStatus == 'accepted') ...[
                            const SizedBox(height: 12),
                            const Text(
                              'The verified EUDI details were saved to your profile.',
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
                if (_authorizationRequest != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Authorization request',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SelectableText(
                      _authorizationRequest!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                if (_verificationSessionId != null)
                  Text('Session ID: $_verificationSessionId'),
                const SizedBox(height: 12),
                if (_verificationStatus != 'verified' &&
                    _verificationStatus != 'accepted') ...[
                  if (_authorizationRequest != null) ...[
                    FilledButton.icon(
                      onPressed: () => _openWallet(),
                      icon: const Icon(Icons.open_in_new_rounded),
                      label: const Text('Open EUDI Wallet'),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      if (_authorizationRequest != null) ...[
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _copyRequest,
                            icon: const Icon(Icons.copy_all_rounded),
                            label: const Text('Copy request'),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _startVerification,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Create new request'),
                        ),
                      ),
                    ],
                  ),
                ],
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isLoading || _isRestoringSession
                        ? null
                        : _startVerification,
                    icon: _isLoading || _isRestoringSession
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: TriangleLoadingIndicator(
                              size: 18,
                              showFill: false,
                              strokeColor: Theme.of(
                                context,
                              ).colorScheme.onSurface,
                            ),
                          )
                        : const Icon(Icons.verified_user_outlined),
                    label: Text(
                      _isRestoringSession
                          ? 'Checking for a completed verification…'
                          : _isLoading
                          ? 'Generating request…'
                          : 'Start PID verification',
                    ),
                  ),
                ),
              ],
            ],
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
        : 'Not provided';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(comparison.label, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 2),
        Table(
          columnWidths: const {0: FixedColumnWidth(112), 1: FlexColumnWidth()},
          defaultVerticalAlignment: TableCellVerticalAlignment.top,
          children: [
            _valueRow('EUDI original:', comparison.verifiedValue ?? ''),
            _valueRow('Compared as:', comparison.normalizedVerifiedValue ?? ''),
            _valueRow('Profile:', profileValue),
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
