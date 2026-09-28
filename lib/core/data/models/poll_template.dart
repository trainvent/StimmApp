/// Only selected fields are stored; absent fields leave the current form unchanged.
class PollTemplate {
  const PollTemplate({
    required this.id,
    required this.name,
    this.title,
    this.description,
    this.questions,
    this.tags,
    this.scopeType,
    this.countryUnion,
    this.durationDays,
    this.openUntilClosed,
    this.includesAudience = false,
    this.groupId,
  });

  final String id;
  final String name;
  final String? title;
  final String? description;
  final List<PollTemplateQuestion>? questions;
  final List<String>? tags;
  final String? scopeType;
  final String? countryUnion;
  final int? durationDays;
  final bool? openUntilClosed;
  final bool includesAudience;
  final String? groupId;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (title != null) 'title': title,
    if (description != null) 'description': description,
    if (questions != null)
      'questions': questions!.map((question) => question.toJson()).toList(),
    if (tags != null) 'tags': tags,
    if (scopeType != null) 'scopeType': scopeType,
    if (countryUnion != null) 'countryUnion': countryUnion,
    if (durationDays != null) 'durationDays': durationDays,
    if (openUntilClosed != null) 'openUntilClosed': openUntilClosed,
    if (includesAudience) 'includesAudience': true,
    if (includesAudience) 'groupId': groupId,
  };

  factory PollTemplate.fromJson(Map<String, dynamic> json) => PollTemplate(
    id: json['id'] as String,
    name: json['name'] as String,
    title: json['title'] as String?,
    description: json['description'] as String?,
    tags: (json['tags'] as List?)?.cast<String>(),
    scopeType: json['scopeType'] as String?,
    countryUnion: json['countryUnion'] as String?,
    durationDays: json['durationDays'] as int?,
    openUntilClosed: json['openUntilClosed'] as bool?,
    includesAudience: json['includesAudience'] as bool? ?? false,
    groupId: json['groupId'] as String?,
    questions: (json['questions'] as List?)
        ?.map(
          (question) => PollTemplateQuestion.fromJson(
            Map<String, dynamic>.from(question as Map),
          ),
        )
        .toList(),
  );
}

class PollTemplateQuestion {
  const PollTemplateQuestion({required this.title, required this.options});
  final String title;
  final List<String> options;

  Map<String, dynamic> toJson() => {'title': title, 'options': options};
  factory PollTemplateQuestion.fromJson(Map<String, dynamic> json) =>
      PollTemplateQuestion(
        title: json['title'] as String,
        options: List<String>.from(json['options'] as List),
      );
}
