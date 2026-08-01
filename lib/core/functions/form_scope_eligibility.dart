import 'package:stimmapp/core/constants/eu_country_codes.dart';
import 'package:stimmapp/core/data/models/home_item.dart';
import 'package:stimmapp/core/data/models/user_profile.dart';

bool isHomeItemInUserZone({
  required HomeItem item,
  required UserProfile? userProfile,
}) {
  final userCountryCode =
      userProfile?.countryCode?.toUpperCase() ??
      (userProfile?.supportsStateScope == true ? 'DE' : null);
  final userStateOrRegion = userProfile?.state;
  final userTown = userProfile?.town?.trim().toLowerCase();
  final itemCountryCode = item.countryCode?.toUpperCase();
  final itemStateOrRegion = item.stateOrRegion;
  final itemTown = item.town?.trim().toLowerCase();

  switch (normalizedHomeItemScopeType(item)) {
    case 'global':
      return true;
    case 'eu':
      return isEuCountryCode(userCountryCode);
    case 'continent':
      if ((item.continentCode ?? '').toUpperCase() == 'EU') {
        return isEuCountryCode(userCountryCode);
      }
      return true;
    case 'country':
      return userCountryCode != null &&
          userCountryCode.isNotEmpty &&
          itemCountryCode != null &&
          itemCountryCode.isNotEmpty &&
          userCountryCode == itemCountryCode;
    case 'stateOrRegion':
      if (userCountryCode == null || userCountryCode.isEmpty) return false;
      if (itemCountryCode == null || itemCountryCode.isEmpty) return false;
      if (userCountryCode != itemCountryCode) return false;
      if (itemStateOrRegion == null || itemStateOrRegion.isEmpty) return true;
      return userStateOrRegion == itemStateOrRegion;
    case 'city':
    case 'town':
      if (userCountryCode == null || userCountryCode.isEmpty) return false;
      if (itemCountryCode == null || itemCountryCode.isEmpty) return false;
      if (userCountryCode != itemCountryCode) return false;
      if (itemStateOrRegion != null && itemStateOrRegion.isNotEmpty) {
        if (userStateOrRegion != itemStateOrRegion) return false;
      }
      if (itemTown == null || itemTown.isEmpty) return true;
      return userTown != null && userTown.isNotEmpty && userTown == itemTown;
    default:
      return true;
  }
}

List<T> filterHomeItemsInUserZone<T extends HomeItem>({
  required Iterable<T> items,
  required UserProfile? userProfile,
}) {
  return items
      .where(
        (item) => isHomeItemInUserZone(item: item, userProfile: userProfile),
      )
      .toList();
}

String normalizedHomeItemScopeType(HomeItem item) {
  final itemCountryCode = item.countryCode?.toUpperCase();
  final itemStateOrRegion = item.stateOrRegion;
  final itemTown = item.town?.trim().toLowerCase();
  final hasLegacyScopeData =
      (itemCountryCode != null && itemCountryCode.isNotEmpty) ||
      (itemStateOrRegion != null && itemStateOrRegion.isNotEmpty) ||
      (itemTown != null && itemTown.isNotEmpty);

  if (item.scopeType.isNotEmpty) return item.scopeType;
  if (itemTown != null && itemTown.isNotEmpty) return 'city';
  if (!hasLegacyScopeData) return 'global';
  return itemStateOrRegion != null && itemStateOrRegion.isNotEmpty
      ? 'stateOrRegion'
      : 'country';
}
