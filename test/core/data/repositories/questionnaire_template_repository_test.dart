import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stimmapp/core/data/models/form_template.dart';
import 'package:stimmapp/core/data/repositories/questionnaire_template_repository.dart';

void main() {
  const template = FormTemplate(
    id: 'template-1',
    name: 'Weekly decision',
    title: 'Next meeting',
    description: 'Our recurring meeting',
    questions: [
      FormTemplateQuestion(
        title: 'Do you agree?',
        options: ['Yes', 'Undecided', 'No', 'Veto'],
      ),
    ],
  );

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'content survives repository recreation and remains separate from drafts',
    () async {
      final prefs = await SharedPreferences.getInstance();
      await QuestionnaireTemplateRepository(prefs, 'alice').save(template);
      await prefs.setString('draft_poll_specific_v1', 'draft');
      await prefs.remove('draft_poll_specific_v1');
      final loaded = QuestionnaireTemplateRepository(
        prefs,
        'alice',
      ).load().single;
      expect(loaded.toJson(), template.toJson());
      expect(loaded.toJson().containsKey('groupId'), isFalse);
    },
  );

  test('templates are isolated by account and deletion only affects the chosen template', () async {
    final prefs = await SharedPreferences.getInstance();
    final alice = QuestionnaireTemplateRepository(prefs, 'alice');
    final bob = QuestionnaireTemplateRepository(prefs, 'bob');
    await alice.save(template);
    expect(bob.load(), isEmpty);
    await bob.save(template);
    await alice.delete(template.id);
    expect(alice.load(), isEmpty);
    expect(bob.load().single.name, template.name);
  });

  test('saving the same id updates instead of duplicating', () async {
    final repository = QuestionnaireTemplateRepository(
      await SharedPreferences.getInstance(),
      'alice',
    );
    await repository.save(template);
    await repository.save(template);
    expect(repository.load(), hasLength(1));
  });

  test(
    'invalid persisted data raises an error instead of overwriting templates',
    () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('poll_templates_v1_alice', ['invalid json']);
      final repository = QuestionnaireTemplateRepository(prefs, 'alice');
      await expectLater(repository.save(template), throwsFormatException);
      expect(prefs.getStringList('poll_templates_v1_alice'), ['invalid json']);
    },
  );
  test(
    'updates matching names, ignoring case and surrounding whitespace',
    () async {
      final repository = QuestionnaireTemplateRepository(
        await SharedPreferences.getInstance(),
        'alice',
      );
      await repository.save(template);
      for (final name in [
        'Weekly decision',
        'weekly DECISION',
        '  Weekly decision  ',
      ]) {
        await repository.save(
          FormTemplate(id: 'another', name: name, title: 'Updated'),
        );
        final saved = repository.load().single;
        expect(saved.id, template.id);
        expect(saved.title, 'Updated');
        expect(saved.description, isNull);
        expect(saved.questions, isNull);
      }
      await repository.delete(template.id);
      await repository.save(
        const FormTemplate(id: 'another', name: 'Weekly decision'),
      );
      expect(repository.load().single.id, 'another');
    },
  );
}
