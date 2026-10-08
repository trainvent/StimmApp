import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:stimmapp/core/data/models/survey.dart';
import 'package:stimmapp/core/data/services/file_output/survey_export_answers.dart';
import 'package:stimmapp/core/data/services/file_output/export_document.dart';
import 'package:stimmapp/core/data/services/file_output/to_csv.dart';
import 'package:stimmapp/core/data/services/file_output/to_json.dart';

void main() {
  const questions = [
    SurveyQuestion(
      id: 'choice',
      title: 'Pick',
      options: [SurveyOption(id: 'a', label: 'Trees')],
    ),
    SurveyQuestion(
      id: 'text',
      title: 'Explain',
      type: SurveyQuestionType.text,
      options: [],
    ),
  ];
  test('exports both answer stores in question order without losing text', () {
    const text = 'More trees, please!\nEspecially "oaks" — danke.';
    final answers = surveyExportAnswers(questions, {
      'answers': {'choice': 'a', 'text': 'wrong store'},
      'textAnswers': {'text': text, 'choice': 'wrong store'},
    });
    expect(answers, ['Trees', text]);
    final document = ExportDocument(
      rows: [
        ['Pick', 'Explain'],
        answers,
      ],
    );
    final json = jsonDecode(const JsonExportService().build(document));
    expect(json[0]['Explain'], text);
    expect(const CsvExportService().build(document), contains('""oaks""'));
  });
  test('missing text stays blank and legacy choices retain their label', () {
    expect(
      surveyExportAnswers(questions, {
        'answers': {'choice': 'a'},
      }),
      ['Trees', ''],
    );
    expect(surveyExportAnswers(questions, {}), ['', '']);
  });
}
