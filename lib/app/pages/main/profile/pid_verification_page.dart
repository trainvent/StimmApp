import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:stimmapp/app/scaffolds/app_bar_scaffold.dart';
import 'package:stimmapp/app/widgets/snackbar_utils.dart';
import 'package:stimmapp/core/data/services/pid_verification_service.dart';
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

class _PidVerificationPageState extends ConsumerState<PidVerificationPage> {
  bool _isLoading = false;
  String? _authorizationRequest;
  String? _verificationSessionId;
  String? _error;
  String? _purpose;
  DateTime? _expiresAt;

  Future<void> _startVerification() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      setState(() {
        _error = 'You need to be signed in to verify your identity.';
      });
      return;
    }

    final userProfile = ref.read(userProfileProvider).asData?.value;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await pidVerificationService.createRequest(
        reverify: widget.reverify || userProfile?.isVerified == true,
      );
      if (!mounted) return;
      final expiresAt = DateTime.tryParse(response.expiresAt);
      setState(() {
        _authorizationRequest = response.authorizationRequest;
        _verificationSessionId = response.verificationSessionId;
        _purpose = response.purpose;
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
    final isVerified = widget.reverify || userProfile?.isVerified == true;
    final requestedMode = isVerified ? 'reverification' : 'registration';

    return AppBarScaffold(
      title: 'PID verification',
      child: SafeArea(
        child: SingleChildScrollView(
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
              else if (_authorizationRequest == null)
                const SizedBox.shrink(),
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
                const SizedBox(height: 8),
                if (_verificationSessionId != null)
                  Text('Session ID: $_verificationSessionId'),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => _openWallet(),
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: const Text('Open EUDI Wallet'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _copyRequest,
                        icon: const Icon(Icons.copy_all_rounded),
                        label: const Text('Copy request'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _startVerification,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Refresh'),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isLoading ? null : _startVerification,
                    icon: _isLoading
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
                      _isLoading
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
