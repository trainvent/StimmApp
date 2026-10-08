import 'package:stimmapp/core/data/models/survey.dart';

/// Builds one response row in question order for every export format.
List<String> surveyExportAnswers(
  List<SurveyQuestion> questions,
  Map<String, dynamic> response,
) {
  final choices = response['answers'] as Map? ?? const {};
  final texts = response['textAnswers'] as Map? ?? const {};
  return questions.map((question) {
    if (question.isText) return texts[question.id] as String? ?? '';
    final answer = choices[question.id] as String? ?? '';
    for (final option in question.options) {
      if (option.id == answer) return option.label;
    }
    return answer;
  }).toList();
}
