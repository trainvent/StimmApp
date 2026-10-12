import 'package:stimmapp/core/data/models/home_item.dart';

enum QuestionnaireKind { poll, survey }

/// Shared publication category; Poll and Survey retain their own storage formats.
abstract class Questionnaire extends HomeItem {
  const Questionnaire();

  QuestionnaireKind get kind;
  DateTime get createdAt;
  String? get groupId;
  String? get groupName;
}

class QuestionnaireOption {
  final String id;
  final String label;

  const QuestionnaireOption({required this.id, required this.label});

  factory QuestionnaireOption.fromMap(Map<String, dynamic> map) {
    return QuestionnaireOption(
      id: (map['id'] ?? '') as String,
      label: (map['label'] ?? '') as String,
    );
  }

  Map<String, dynamic> toMap() => {'id': id, 'label': label};
}

enum QuestionnaireQuestionType { multipleChoice, text }

class QuestionnaireQuestion {
  final String id;
  final String title;
  final List<QuestionnaireOption> options;
  final QuestionnaireQuestionType type;

  bool get isText => type == QuestionnaireQuestionType.text;

  const QuestionnaireQuestion({
    required this.id,
    required this.title,
    required this.options,
    this.type = QuestionnaireQuestionType.multipleChoice,
  });

  factory QuestionnaireQuestion.fromMap(Map<String, dynamic> map) {
    return QuestionnaireQuestion(
      id: (map['id'] ?? '') as String,
      title: (map['title'] ?? '') as String,
      type: map['type'] == 'text'
          ? QuestionnaireQuestionType.text
          : QuestionnaireQuestionType.multipleChoice,
      options:
          (map['options'] as List?)
              ?.map(
                (item) => QuestionnaireOption.fromMap(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'type': type.name,
    'options': options.map((option) => option.toMap()).toList(),
  };
}
