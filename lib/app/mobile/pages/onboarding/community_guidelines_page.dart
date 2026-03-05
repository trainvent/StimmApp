import 'package:flutter/material.dart';
import 'package:stimmapp/app/mobile/widgets/buttons/button_widget.dart';
import 'package:stimmapp/app/mobile/widgets/snackbar_utils.dart';
import 'package:stimmapp/core/constants/internal_constants.dart';
import 'package:stimmapp/core/data/models/user_profile.dart';
import 'package:stimmapp/core/data/repositories/user_repository.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';
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
      showErrorSnackBar(context.l10n.couldNotOpenLink);
    }
  }

  Future<void> _accept() async {
    if (!_accepted) {
      showErrorSnackBar(context.l10n.acceptCommunityRulesBeforeContinuing);
      return;
    }

    setState(() => _saving = true);
    try {
      await UserRepository.create().upsert(
        widget.profile.copyWith(acceptedCommunityRulesAt: DateTime.now()),
      );
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context.l10n.couldNotSaveYourAcceptance(e.toString()));
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.communityRules)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.communityRulesZeroTolerance,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Text(context.l10n.communityRulesAgreementNotice),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => _openUrl(IConst.termsOfServiceUrl),
                child: Text(context.l10n.openTermsOfService),
              ),
              TextButton(
                onPressed: () => _openUrl(IConst.privacyPolicyUrl),
                child: Text(context.l10n.openPrivacyPolicy),
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _accepted,
                onChanged: (value) =>
                    setState(() => _accepted = value ?? false),
                title: Text(context.l10n.communityRulesAcceptance),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ButtonWidget(
                  label: _saving
                      ? context.l10n.saving
                      : context.l10n.continueText,
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
