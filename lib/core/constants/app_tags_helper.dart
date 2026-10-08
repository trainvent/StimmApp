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
      "Human Rights": context.l10n.tagHumanRights,
      "Economic Justice": context.l10n.tagEconomicJustice,
      "Local Government": context.l10n.tagLocalGovernment,
      "Regional Government": context.l10n.tagRegionalGovernment,
      "Family": context.l10n.tagFamily,
      "Entertainment": context.l10n.tagEntertainment,
      "Animal Rights": context.l10n.tagAnimalRights,
      "Criminal Justice": context.l10n.tagCriminalJustice,
      "Children’s Rights": context.l10n.tagChildrensRights,
      "Education Reform": context.l10n.tagEducationReform,
      "Education Infrastructure": context.l10n.tagEducationInfrastructure,
      "Public Health": context.l10n.tagPublicHealth,
      "Migration and Integration": context.l10n.tagMigrationIntegration,
      "Access to Care": context.l10n.tagAccessToCare,
      "Elections and Voting Rights": context.l10n.tagVotingRights,
      "Family Rights": context.l10n.tagFamilyRights,
      "Climate Protection": context.l10n.tagClimateProtection,
      "Women’s Rights": context.l10n.tagWomensRights,
      "Consumer Rights": context.l10n.tagConsumerRights,
      'Other': context.l10n.tagOther,
    };
  }

  static String getLocalizedTag(BuildContext context, String tagKey) {
    final tags = getTags(context);
    return tags[tagKey] ?? tagKey;
  }
}
