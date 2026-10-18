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
      expect(prefs.getString('links_test_websiteUrl'), '');
    },
  );
}
