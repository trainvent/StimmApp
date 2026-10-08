import 'package:flutter_test/flutter_test.dart';
import 'package:stimmapp/core/data/services/pdf_form_import.dart';
import 'package:stimmapp/core/data/models/survey.dart';

void main() {
  test('imports explicit choices, wrapped answers and written questions', () {
    final form = PdfFormImport.parse('''Community survey
Please share your views on our local community.
1. Which option do you prefer?
a) A greener
neighbourhood
b) Better transport
2. What else should change?
''', type: 'poll');
    expect(form.title, 'Community survey');
    expect(form.questions, hasLength(2));
    expect(form.questions!.first.options, [
      'A greener neighbourhood',
      'Better transport',
    ]);
    expect(form.questions!.last.type, SurveyQuestionType.text);
    expect(form.tags, isNull);
    expect(form.scopeType, isNull);
  });

  test('petition retains numbered body paragraphs', () {
    final form = PdfFormImport.parse('''Protect our park
We ask the council to protect our community park.
1. Keep the existing trees.
2. Preserve public access.''', type: 'petition');
    expect(form.description, contains('1. Keep'));
    expect(form.questions, isNull);
  });

  test('rejects missing content and malformed choices without truncation', () {
    for (final text in [
      '',
      'Title only',
      'Survey title\nA sufficiently long description here.\n1. Choose one\na) Only choice',
    ]) {
      expect(
        () => PdfFormImport.parse(text, type: 'poll'),
        throwsFormatException,
      );
    }
  });
}
