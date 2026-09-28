import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stimmapp/core/data/models/poll_template.dart';
import 'package:stimmapp/core/data/repositories/poll_template_repository.dart';

void main() {
  const template = PollTemplate(
    id: 'template-1',
    name: 'Weekly decision',
    title: 'Next meeting',
    description: 'Our recurring meeting',
    questions: [
      PollTemplateQuestion(
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
      await PollTemplateRepository(prefs, 'alice').save(template);
      await prefs.setString('draft_poll_specific_v1', 'draft');
      await prefs.remove('draft_poll_specific_v1');
      final loaded = PollTemplateRepository(prefs, 'alice').load().single;
      expect(loaded.toJson(), template.toJson());
      expect(loaded.toJson().containsKey('groupId'), isFalse);
    },
  );

  test(
    'templates are isolated by account and deletion only affects the chosen template',
    () async {
      final prefs = await SharedPreferences.getInstance();
      final alice = PollTemplateRepository(prefs, 'alice');
      final bob = PollTemplateRepository(prefs, 'bob');
      await alice.save(template);
      expect(bob.load(), isEmpty);
      await bob.save(template);
      await alice.delete(template.id);
      expect(alice.load(), isEmpty);
      expect(bob.load().single.name, template.name);
    },
  );

  test('saving the same id updates instead of duplicating', () async {
    final repository = PollTemplateRepository(
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
      final repository = PollTemplateRepository(prefs, 'alice');
      await expectLater(repository.save(template), throwsFormatException);
      expect(prefs.getStringList('poll_templates_v1_alice'), ['invalid json']);
    },
  );
}
