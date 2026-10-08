import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stimmapp/app/pages/main/profile/public_profile_page.dart';
import 'package:stimmapp/core/data/di/service_locator.dart';

import '../../../../../test_helper.dart';

void main() {
  testWidgets(
    'public profile shows nickname and public forms without personal details',
    (tester) async {
      final widget = createTestWidget(
        const ProviderScope(child: PublicProfilePage(userId: 'author')),
      );
      final db = locator.databaseService.instance;
      await db.collection('users').doc('author').set({
        'displayName': 'Creator nickname',
        'email': 'private@example.com',
        'givenName': 'Private name',
        'address': 'Private address',
      });
      await db.collection('polls').doc('public').set({
        'createdBy': 'author',
        'title': 'Public poll',
        'visibility': 'public',
      });
      await db.collection('polls').doc('private').set({
        'createdBy': 'author',
        'title': 'Group-only poll',
        'visibility': 'group',
      });
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();
      expect(find.text('Creator nickname'), findsOneWidget);
      expect(find.text('Public poll'), findsOneWidget);
      expect(find.text('Group-only poll'), findsNothing);
      expect(find.text('private@example.com'), findsNothing);
      expect(find.text('Private name'), findsNothing);
      expect(find.text('Private address'), findsNothing);
    },
  );

  testWidgets('missing public profile shows not found', (tester) async {
    await tester.pumpWidget(
      createTestWidget(
        const ProviderScope(child: PublicProfilePage(userId: 'missing')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Not found'), findsOneWidget);
  });
}
