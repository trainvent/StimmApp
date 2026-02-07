import 'package:flutter/material.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';

class PollTutorialStep {
  final String title;
  final String description;

  PollTutorialStep({required this.title, required this.description});
}

class PollTutorialHelper {
  static List<PollTutorialStep> getSteps(BuildContext context) {
    return [
      PollTutorialStep(
        title: context.l10n.pollTutorialStep1Title,
        description: context.l10n.pollTutorialStep1Desc,
      ),
      PollTutorialStep(
        title: context.l10n.pollTutorialStep2Title,
        description: context.l10n.pollTutorialStep2Desc,
      ),
      PollTutorialStep(
        title: context.l10n.pollTutorialStep3Title,
        description: context.l10n.pollTutorialStep3Desc,
      ),
      PollTutorialStep(
        title: context.l10n.pollTutorialStep4Title,
        description: context.l10n.pollTutorialStep4Desc,
      ),
      PollTutorialStep(
        title: context.l10n.pollTutorialStep5Title,
        description: context.l10n.pollTutorialStep5Desc,
      ),
      PollTutorialStep(
        title: context.l10n.pollTutorialStep6Title,
        description: context.l10n.pollTutorialStep6Desc,
      ),
      PollTutorialStep(
        title: context.l10n.pollTutorialStep7Title,
        description: context.l10n.pollTutorialStep7Desc,
      ),
    ];
  }
}
