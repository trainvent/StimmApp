abstract class HomeItem {
  String get id;
  String get title;
  String get description;
  String get createdBy;
  String get status;
  String? get state;
  DateTime get expiresAt;
  int get participantCount;
  List<String> get tags;
}
