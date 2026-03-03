import 'package:flutter/material.dart';
import 'package:stimmapp/app/mobile/widgets/buttons/button_widget.dart';
import 'package:stimmapp/app/mobile/widgets/snackbar_utils.dart';
import 'package:stimmapp/core/constants/internal_constants.dart';
import 'package:stimmapp/core/data/models/user_profile.dart';
import 'package:stimmapp/core/data/repositories/user_repository.dart';
import 'package:url_launcher/url_launcher.dart';

class CommunityGuidelinesPage extends StatefulWidget {
  const CommunityGuidelinesPage({super.key, required this.profile});

  final UserProfile profile;

  @override
  State<CommunityGuidelinesPage> createState() =>
      _CommunityGuidelinesPageState();
}

class _CommunityGuidelinesPageState extends State<CommunityGuidelinesPage> {
  bool _accepted = false;
  bool _saving = false;

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      showErrorSnackBar('Could not open link.');
    }
  }

  Future<void> _accept() async {
    if (!_accepted) {
      showErrorSnackBar(
        'Please accept the community rules and terms before continuing.',
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await UserRepository.create().upsert(
        widget.profile.copyWith(acceptedCommunityRulesAt: DateTime.now()),
      );
    } catch (e) {
      showErrorSnackBar('Could not save your acceptance: $e');
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Community Rules')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'StimmApp has zero tolerance for objectionable content, harassment, hate speech, sexual exploitation, or abusive users.',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              const Text(
                'By continuing, you agree to the Terms of Service and confirm that you will only publish lawful, respectful content. Reported abusive content may be removed and abusive users may be suspended or permanently removed.',
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => _openUrl(IConst.termsOfServiceUrl),
                child: const Text('Open Terms of Service'),
              ),
              TextButton(
                onPressed: () => _openUrl(IConst.privacyPolicyUrl),
                child: const Text('Open Privacy Policy'),
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _accepted,
                onChanged: (value) =>
                    setState(() => _accepted = value ?? false),
                title: const Text(
                  'I agree to the Terms of Service and understand that StimmApp does not tolerate objectionable content or abusive behavior.',
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ButtonWidget(
                  label: _saving ? 'Saving...' : 'Continue',
                  callback: _saving ? null : _accept,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
