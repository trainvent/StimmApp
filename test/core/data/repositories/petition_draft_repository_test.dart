import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stimmapp/core/data/models/petition_draft.dart';
import 'package:stimmapp/core/data/models/poll_template.dart';
import 'package:stimmapp/core/data/repositories/petition_draft_repository.dart';

void main() {
  test(
    'unfinished petitions and images survive reload, update and deletion',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final repository = PetitionDraftRepository(preferences, 'alice');
      const first = PetitionDraft(
        form: PollTemplate(
          id: 'one',
          name: '',
          title: '',
          description: 'Unfinished',
          tags: ['Environment'],
          scopeType: 'country',
          durationDays: 12,
          openUntilClosed: true,
          imageUrl: 'https://example.com/image.jpg',
        ),
        imageBase64: 'aW1hZ2U=',
      );
      await repository.save(first);
      await repository.save(
        const PetitionDraft(
          form: PollTemplate(id: 'two', name: 'Other'),
        ),
      );
      final restored = PetitionDraftRepository(preferences, 'alice').load();
      expect(restored.length, 2);
      expect(restored.last.toJson(), first.toJson());
      expect(PetitionDraftRepository(preferences, 'bob').load(), isEmpty);
      await repository.save(
        const PetitionDraft(
          form: PollTemplate(id: 'one', name: '', title: 'Completed title'),
        ),
      );
      expect(repository.load().length, 2);
      expect(repository.load().first.form.title, 'Completed title');
      expect(repository.load().first.imageBase64, isNull);
      await repository.delete('one');
      expect(repository.load().single.form.id, 'two');
    },
  );
}
