import 'package:stimmapp/core/data/models/form_scope.dart';

abstract class HomeItem {
  const HomeItem();

  String get id;
  String get title;
  String get description;
  String get createdBy;
  String get status;
  FormScope get scope;
  DateTime? get expiresAt;
  DateTime? get scheduledCloseAt;
  int get participantCount;
  List<String> get tags;

  bool isExpiredAt(DateTime dateTime) {
    final expiry = expiresAt;
    return expiry != null && !expiry.isAfter(dateTime);
  }

  String get scopeType => scope.firestoreType;
  String? get scopeUnionCode => scope.countryUnion?.code;
  String? get continentCode => scope.continentCode;
  String? get countryCode => scope.countryCode;
  String? get stateOrRegion => scope.stateOrRegion;
  String? get town => scope.town;
  String? get city => scope.town;
  String? get state => scope.stateOrRegion;
}
