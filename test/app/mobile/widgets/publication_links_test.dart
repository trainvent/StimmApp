import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stimmapp/app/pages/main/home/creator/base_creator_page.dart';
import 'package:stimmapp/app/widgets/publication_links.dart';
import 'package:stimmapp/core/data/models/form_template.dart';
import 'package:stimmapp/core/data/models/publication_links.dart';

import '../../../test_helper.dart';

void main() {
  testWidgets(
    'hides missing/unsafe links and labels valid links with their domains',
    (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const Scaffold(
            body: PublicationLinksView(
              links: PublicationLinks(
                youtubeUrl: 'https://evil.org/video',
                websiteUrl: 'javascript:alert(1)',
              ),
            ),
          ),
        ),
      );
      expect(find.byType(ListTile), findsNothing);
      await tester.pumpWidget(
        createTestWidget(
          const Scaffold(
            body: PublicationLinksView(
              links: PublicationLinks(
                youtubeUrl: 'https://youtu.be/dQw4w9WgXcQ',
                websiteUrl: 'https://example.org/about',
              ),
            ),
          ),
        ),
      );
      expect(find.text('Watch video'), findsOneWidget);
      expect(find.text('Open website'), findsOneWidget);
      expect(find.text('example.org'), findsOneWidget);
    },
  );

  testWidgets(
    'creator restores optional links from drafts and applies/clears template links',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'links_test_youtubeUrl': 'https://youtu.be/dQw4w9WgXcQ',
        'links_test_websiteUrl': 'https://example.org',
      });
      final key = GlobalKey<BaseCreatorPageState>();
      await tester.pumpWidget(
        createTestWidget(
          BaseCreatorPage(
            key: key,
            title: 'Create petition',
            draftStorageKey: 'links_test',
            tutorialSteps: const [],
            profileLoader: () async => null,
            onSubmit: ({
              required title,
              required description,
              required tags,
              required scope,
              required durationDays,
              required openUntilClosed,
            }) async => false,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        key.currentState!.publicationLinks.websiteUrl,
        'https://example.org',
      );
      expect(
        key.currentState!.publicationLinks.youtubeUrl,
        'https://youtu.be/dQw4w9WgXcQ',
      );
      await key.currentState!.applyTemplate(
        const FormTemplate(
          id: 'empty',
          name: 'Clear links',
          links: PublicationLinks(),
        ),
      );
      await tester.pumpAndSettle();
      expect(key.currentState!.publicationLinks.toJson(), isEmpty);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('links_test_links'), ['', '']);
      expect(prefs.containsKey('links_test_websiteUrl'), isFalse);
    },
  );
  testWidgets(
    'one bottom link field detects websites and videos and reveals the second field',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final key = GlobalKey<BaseCreatorPageState>();
      await tester.pumpWidget(
        createTestWidget(
          BaseCreatorPage(
            key: key,
            title: 'Create petition',
            tutorialSteps: const [],
            profileLoader: () async => null,
            onSubmit: ({
              required title,
              required description,
              required tags,
              required scope,
              required durationDays,
              required openUntilClosed,
            }) async => false,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final first = find.byKey(const ValueKey('publicationLink0'));
      final second = find.byKey(const ValueKey('publicationLink1'));
      await tester.scrollUntilVisible(
        first,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(second, findsNothing);
      await tester.enterText(first, 'https://example.org');
      await tester.pumpAndSettle();
      expect(second, findsOneWidget);
      expect(
        key.currentState!.publicationLinks.websiteUrl,
        'https://example.org',
      );
      expect(key.currentState!.publicationLinks.youtubeUrl, isNull);
      await tester.ensureVisible(second);
      await tester.enterText(second, 'https://youtu.be/dQw4w9WgXcQ');
      await tester.pumpAndSettle();
      expect(
        key.currentState!.publicationLinks.youtubeUrl,
        'https://youtu.be/dQw4w9WgXcQ',
      );
      expect(find.byIcon(Icons.play_circle_outline), findsOneWidget);
      // Either order works: detection is based on the URL, not the field position.
      await tester.enterText(second, 'https://second.example.org');
      await tester.pumpAndSettle();
      expect(
        find.text('You can add one YouTube video and one website link.'),
        findsWidgets,
      );
      await tester.enterText(second, '');
      await tester.ensureVisible(first);
      await tester.enterText(first, 'https://youtu.be/dQw4w9WgXcQ');
      await tester.pumpAndSettle();
      expect(
        key.currentState!.publicationLinks.youtubeUrl,
        'https://youtu.be/dQw4w9WgXcQ',
      );
      expect(key.currentState!.publicationLinks.websiteUrl, isNull);
    },
  );
}
