import 'package:flutter/material.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';

class PetitionTutorialHelper {
  static List<String> getSteps(BuildContext context) {
    return [
      context.l10n.petitionTutorialStep1,
      context.l10n.petitionTutorialStep2,
      context.l10n.petitionTutorialStep3,
      context.l10n.petitionTutorialStep4,
      context.l10n.petitionTutorialStep5,
    ];
  }
}
