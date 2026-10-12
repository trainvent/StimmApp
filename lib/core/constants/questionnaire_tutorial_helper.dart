import 'package:flutter/material.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';

class QuestionnaireTutorialStep {
  final String title;
  final String description;

  QuestionnaireTutorialStep({required this.title, required this.description});
}

class QuestionnaireTutorialHelper {
  static List<QuestionnaireTutorialStep> getSteps(BuildContext context) {
    return [
      QuestionnaireTutorialStep(
        title: context.l10n.questionnaireTutorialStep1Title,
        description: context.l10n.questionnaireTutorialStep1Desc,
      ),
      QuestionnaireTutorialStep(
        title: context.l10n.questionnaireTutorialStep2Title,
        description: context.l10n.questionnaireTutorialStep2Desc,
      ),
      QuestionnaireTutorialStep(
        title: context.l10n.questionnaireTutorialStep3Title,
        description: context.l10n.questionnaireTutorialStep3Desc,
      ),
      QuestionnaireTutorialStep(
        title: context.l10n.questionnaireTutorialStep4Title,
        description: context.l10n.questionnaireTutorialStep4Desc,
      ),
      QuestionnaireTutorialStep(
        title: context.l10n.questionnaireTutorialStep5Title,
        description: context.l10n.questionnaireTutorialStep5Desc,
      ),
      QuestionnaireTutorialStep(
        title: context.l10n.questionnaireTutorialStep6Title,
        description: context.l10n.questionnaireTutorialStep6Desc,
      ),
      QuestionnaireTutorialStep(
        title: context.l10n.questionnaireTutorialStep7Title,
        description: context.l10n.questionnaireTutorialStep7Desc,
      ),
    ];
  }
}
