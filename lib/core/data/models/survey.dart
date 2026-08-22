import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stimmapp/core/constants/app_limits.dart';
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

class Survey extends HomeItem {
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
  final DateTime? expiresAt;
  @override
  final DateTime? scheduledCloseAt;
  @override
  final String status;
  @override
  final FormScope scope;
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
    this.expiresAt,
    this.scheduledCloseAt,
    this.status = IConst.active,
    this.scope = const FormScope.global(),
    this.groupId,
    this.groupName,
    this.visibility = 'public',
  });

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
    DateTime? scheduledCloseAt,
    String? status,
    FormScope? scope,
    String? groupId,
    String? groupName,
    String? visibility,
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
      scheduledCloseAt: scheduledCloseAt ?? this.scheduledCloseAt,
      status: status ?? this.status,
      scope: scope ?? this.scope,
      groupId: groupId ?? this.groupId,
      groupName: groupName ?? this.groupName,
      visibility: visibility ?? this.visibility,
    );
  }

  static Survey fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snap,
    SnapshotOptions? _,
  ) {
    final data = snap.data()!;
    final createdAt =
        (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();

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
      expiresAt: data['openUntilClosed'] == true
          ? null
          : (data['expiresAt'] as Timestamp?)?.toDate() ??
                createdAt.add(
                  const Duration(days: AppLimits.defaultFormDurationDays),
                ),
      scheduledCloseAt: (data['scheduledCloseAt'] as Timestamp?)?.toDate(),
      status: (data['status'] ?? IConst.active) as String,
      scope: FormScope.fromFirestore(data),
      groupId: data['groupId'] as String?,
      groupName: data['groupName'] as String?,
      visibility: (data['visibility'] ?? 'public') as String,
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
      'expiresAt': survey.expiresAt == null
          ? null
          : Timestamp.fromDate(survey.expiresAt!),
      'openUntilClosed': survey.expiresAt == null,
      'scheduledCloseAt': survey.scheduledCloseAt == null
          ? null
          : Timestamp.fromDate(survey.scheduledCloseAt!),
      'status': survey.status,
      'titleLowercase': survey.title.toLowerCase(),
      ...survey.scope.toFirestoreFields(),
      'groupId': survey.groupId,
      'groupName': survey.groupName,
      'visibility': survey.visibility,
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
