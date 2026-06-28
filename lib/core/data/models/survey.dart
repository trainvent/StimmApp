import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stimmapp/core/constants/internal_constants.dart';
import 'package:stimmapp/core/data/models/form_scope.dart';
import 'package:stimmapp/core/data/models/home_item.dart';

class SurveyOption {
  final String id;
  final String label;

  const SurveyOption({required this.id, required this.label});

  factory SurveyOption.fromMap(Map<String, dynamic> map) {
    return SurveyOption(
      id: (map['id'] ?? '') as String,
      label: (map['label'] ?? '') as String,
    );
  }

  Map<String, dynamic> toMap() => {'id': id, 'label': label};
}

class SurveyQuestion {
  final String id;
  final String title;
  final List<SurveyOption> options;

  const SurveyQuestion({
    required this.id,
    required this.title,
    required this.options,
  });

  factory SurveyQuestion.fromMap(Map<String, dynamic> map) {
    return SurveyQuestion(
      id: (map['id'] ?? '') as String,
      title: (map['title'] ?? '') as String,
      options:
          (map['options'] as List?)
              ?.map(
                (item) => SurveyOption.fromMap(Map<String, dynamic>.from(item)),
              )
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'options': options.map((option) => option.toMap()).toList(),
  };
}

class Survey implements HomeItem {
  @override
  final String id;
  @override
  final String title;
  @override
  final String description;
  @override
  final List<String> tags;
  final List<SurveyQuestion> questions;
  final Map<String, Map<String, int>> questionVotes;
  final int responseCount;
  @override
  final String createdBy;
  final DateTime createdAt;
  @override
  final DateTime expiresAt;
  @override
  final String status;
  @override
  final String scopeType;
  @override
  final String? continentCode;
  @override
  final String? countryCode;
  @override
  final String? stateOrRegion;
  @override
  final String? town;
  final String? groupId;
  final String? groupName;
  final String visibility;

  Survey({
    required this.id,
    required this.title,
    required this.description,
    required this.tags,
    required this.questions,
    required this.questionVotes,
    this.responseCount = 0,
    required this.createdBy,
    required this.createdAt,
    required this.expiresAt,
    this.status = IConst.active,
    this.scopeType = 'global',
    this.continentCode,
    this.countryCode,
    this.groupId,
    this.groupName,
    this.visibility = 'public',
    String? stateOrRegion,
    @Deprecated('Use stateOrRegion') String? state,
    String? town,
    @Deprecated('Use town') String? city,
  }) : stateOrRegion = stateOrRegion ?? state,
       town = town ?? city;

  @override
  String? get state => stateOrRegion;

  @override
  String? get city => town;

  @override
  int get participantCount => responseCount;

  int totalVotesForQuestion(String questionId) {
    return questionVotes[questionId]?.values.fold<int>(0, (a, b) => a + b) ?? 0;
  }

  Survey copyWith({
    String? id,
    String? title,
    String? description,
    List<String>? tags,
    List<SurveyQuestion>? questions,
    Map<String, Map<String, int>>? questionVotes,
    int? responseCount,
    String? createdBy,
    DateTime? createdAt,
    DateTime? expiresAt,
    String? status,
    String? scopeType,
    String? continentCode,
    String? countryCode,
    String? groupId,
    String? groupName,
    String? visibility,
    String? stateOrRegion,
    @Deprecated('Use stateOrRegion') String? state,
    String? town,
    @Deprecated('Use town') String? city,
  }) {
    return Survey(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      questions: questions ?? this.questions,
      questionVotes: questionVotes ?? this.questionVotes,
      responseCount: responseCount ?? this.responseCount,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      status: status ?? this.status,
      scopeType: scopeType ?? this.scopeType,
      continentCode: continentCode ?? this.continentCode,
      countryCode: countryCode ?? this.countryCode,
      groupId: groupId ?? this.groupId,
      groupName: groupName ?? this.groupName,
      visibility: visibility ?? this.visibility,
      stateOrRegion: stateOrRegion ?? state ?? this.stateOrRegion,
      town: town ?? city ?? this.town,
    );
  }

  static Survey fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snap,
    SnapshotOptions? _,
  ) {
    final data = snap.data()!;
    final createdAt =
        (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final rawScopeType = data['scopeType'] as String?;
    final countryCode = (data['countryCode'] as String?)?.toUpperCase();
    final stateOrRegion =
        data['stateOrRegion'] as String? ?? data['state'] as String?;
    final town = data['town'] as String? ?? data['city'] as String?;
    final scopeType = rawScopeType != null && rawScopeType.isNotEmpty
        ? formScopeTypeToFirestore(parseFormScopeType(rawScopeType))
        : (town != null && town.isNotEmpty
              ? formScopeTypeToFirestore(FormScopeType.city)
              : (stateOrRegion != null && stateOrRegion.isNotEmpty
                    ? formScopeTypeToFirestore(FormScopeType.stateOrRegion)
                    : (countryCode != null && countryCode.isNotEmpty
                          ? formScopeTypeToFirestore(FormScopeType.country)
                          : formScopeTypeToFirestore(FormScopeType.global))));

    return Survey(
      id: snap.id,
      title: (data['title'] ?? '') as String,
      description: (data['description'] ?? '') as String,
      tags: (data['tags'] as List?)?.cast<String>() ?? const [],
      questions:
          (data['questions'] as List?)
              ?.map(
                (item) =>
                    SurveyQuestion.fromMap(Map<String, dynamic>.from(item)),
              )
              .toList() ??
          const [],
      questionVotes: _questionVotesFromMap(data['questionVotes']),
      responseCount: (data['responseCount'] ?? 0) as int,
      createdBy: (data['createdBy'] ?? '') as String,
      createdAt: createdAt,
      expiresAt:
          (data['expiresAt'] as Timestamp?)?.toDate() ??
          createdAt.add(const Duration(days: 7)),
      status: (data['status'] ?? IConst.active) as String,
      scopeType: scopeType,
      continentCode: data['continentCode'] as String?,
      countryCode: countryCode,
      groupId: data['groupId'] as String?,
      groupName: data['groupName'] as String?,
      visibility: (data['visibility'] ?? 'public') as String,
      stateOrRegion: stateOrRegion,
      town: town,
    );
  }

  static Map<String, Object?> toFirestore(Survey survey, SetOptions? _) {
    return {
      'title': survey.title,
      'description': survey.description,
      'tags': survey.tags,
      'questions': survey.questions.map((q) => q.toMap()).toList(),
      'questionVotes': survey.questionVotes,
      'responseCount': survey.responseCount,
      'createdBy': survey.createdBy,
      'createdAt': Timestamp.fromDate(survey.createdAt),
      'expiresAt': Timestamp.fromDate(survey.expiresAt),
      'status': survey.status,
      'titleLowercase': survey.title.toLowerCase(),
      'scopeType': survey.scopeType,
      'continentCode': survey.continentCode,
      'countryCode': survey.countryCode?.toUpperCase(),
      'groupId': survey.groupId,
      'groupName': survey.groupName,
      'visibility': survey.visibility,
      'stateOrRegion': survey.stateOrRegion,
      'state': survey.stateOrRegion,
      'town': survey.town,
      'city': survey.town,
    };
  }

  static Map<String, Map<String, int>> _questionVotesFromMap(Object? value) {
    final raw = Map<String, dynamic>.from(
      (value as Map?) ?? const <String, dynamic>{},
    );
    return raw.map((questionId, optionCounts) {
      return MapEntry(
        questionId,
        Map<String, int>.from(
          (optionCounts as Map?) ?? const <String, dynamic>{},
        ),
      );
    });
  }
}
