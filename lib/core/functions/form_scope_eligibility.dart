import 'package:stimmapp/core/constants/country_union_memberships.dart';
import 'package:stimmapp/core/data/models/form_scope.dart';
import 'package:stimmapp/core/data/models/home_item.dart';
import 'package:stimmapp/core/data/models/user_profile.dart';

bool isHomeItemInUserZone({
  required HomeItem item,
  required UserProfile? userProfile,
}) => isFormScopeInUserZone(scope: item.scope, userProfile: userProfile);

bool isFormScopeInUserZone({
  required FormScope scope,
  required UserProfile? userProfile,
}) {
  final userCountryCode =
      userProfile?.countryCode?.toUpperCase() ??
      (userProfile?.supportsStateScope == true ? 'DE' : null);
  final userStateOrRegion = userProfile?.state;
  final userTown = userProfile?.town?.trim().toLowerCase();
  final itemCountryCode = scope.countryCode?.toUpperCase();
  final itemStateOrRegion = scope.stateOrRegion;
  final itemTown = scope.town?.trim().toLowerCase();

  switch (scope.type) {
    case FormScopeType.global:
      return true;
    case FormScopeType.countryUnion:
      final union = scope.countryUnion;
      return union != null && isCountryInUnion(userCountryCode, union);
    case FormScopeType.continent:
      return true;
    case FormScopeType.country:
      return userCountryCode != null &&
          userCountryCode.isNotEmpty &&
          itemCountryCode != null &&
          itemCountryCode.isNotEmpty &&
          userCountryCode == itemCountryCode;
    case FormScopeType.stateOrRegion:
      if (userCountryCode == null || userCountryCode.isEmpty) return false;
      if (itemCountryCode == null || itemCountryCode.isEmpty) return false;
      if (userCountryCode != itemCountryCode) return false;
      if (itemStateOrRegion == null || itemStateOrRegion.isEmpty) return true;
      return userStateOrRegion == itemStateOrRegion;
    case FormScopeType.city:
      if (userCountryCode == null || userCountryCode.isEmpty) return false;
      if (itemCountryCode == null || itemCountryCode.isEmpty) return false;
      if (userCountryCode != itemCountryCode) return false;
      if (itemStateOrRegion != null && itemStateOrRegion.isNotEmpty) {
        if (userStateOrRegion != itemStateOrRegion) return false;
      }
      if (itemTown == null || itemTown.isEmpty) return true;
      return userTown != null && userTown.isNotEmpty && userTown == itemTown;
  }
}

List<T> filterHomeItemsInUserZone<T extends HomeItem>({
  required Iterable<T> items,
  required UserProfile? userProfile,
}) => items
    .where((item) => isHomeItemInUserZone(item: item, userProfile: userProfile))
    .toList();

String normalizedHomeItemScopeType(HomeItem item) => item.scope.firestoreType;
