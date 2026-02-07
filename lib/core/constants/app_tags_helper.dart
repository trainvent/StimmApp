import 'package:flutter/material.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';

class AppTagsHelper {
  static Map<String, String> getTags(BuildContext context) {
    return {
      'Environment': context.l10n.tagEnvironment,
      'Politics': context.l10n.tagPolitics,
      'Education': context.l10n.tagEducation,
      'Health': context.l10n.tagHealth,
      'Infrastructure': context.l10n.tagInfrastructure,
      'Economy': context.l10n.tagEconomy,
      'Social': context.l10n.tagSocial,
      'Technology': context.l10n.tagTechnology,
      'Culture': context.l10n.tagCulture,
      'Sports': context.l10n.tagSports,
      'Animal Welfare': context.l10n.tagAnimalWelfare,
      'Safety': context.l10n.tagSafety,
      'Traffic': context.l10n.tagTraffic,
      'Housing': context.l10n.tagHousing,
      'Other': context.l10n.tagOther,
    };
  }

  static String getLocalizedTag(BuildContext context, String tagKey) {
    final tags = getTags(context);
    return tags[tagKey] ?? tagKey;
  }
}
