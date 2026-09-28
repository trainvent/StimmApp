/// Reusable content only: publishing settings and vote identifiers are excluded.
class PollTemplate {
  const PollTemplate({
    required this.id,
    required this.name,
    required this.title,
    required this.description,
    required this.questions,
  });

  final String id;
  final String name;
  final String title;
  final String description;
  final List<PollTemplateQuestion> questions;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'title': title,
    'description': description,
    'questions': questions.map((question) => question.toJson()).toList(),
  };

  factory PollTemplate.fromJson(Map<String, dynamic> json) => PollTemplate(
    id: json['id'] as String,
    name: json['name'] as String,
    title: json['title'] as String,
    description: json['description'] as String,
    questions: (json['questions'] as List)
        .map(
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
