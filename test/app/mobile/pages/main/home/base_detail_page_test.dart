import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stimmapp/app/mobile/pages/main/home/base_detail_page.dart';
import 'package:stimmapp/core/constants/internal_constants.dart';
import 'package:stimmapp/core/data/models/home_item.dart';

import '../../../../../test_helper.dart';

class _TestHomeItem implements HomeItem {
  @override
  final String id;
  @override
  final String title;
  @override
  final String description;
  @override
  final String status;
  @override
  final String? state;
  @override
  final DateTime expiresAt;
  @override
  final int participantCount;
  @override
  final List<String> tags;

  const _TestHomeItem({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.expiresAt,
  });
}

void main() {
  Future<void> pumpPage(
    WidgetTester tester, {
    required _TestHomeItem item,
    Widget? bottomAction,
    VoidCallback? onContentTap,
  }) async {
    await tester.pumpWidget(
      createTestWidget(
        BaseDetailPage<_TestHomeItem>(
          id: item.id,
          appBarTitle: 'Test',
          sharePathSegment: 'test',
          streamProvider: (_) => Stream<_TestHomeItem?>.value(item),
          contentBuilder: (_, _) {
            return TextButton(
              onPressed: onContentTap,
              child: const Text('content_action'),
            );
          },
          bottomAction: bottomAction,
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets(
    'closes UI when status is closed even if expiresAt is in future',
    (tester) async {
      final item = _TestHomeItem(
        id: '1',
        title: 'Title',
        description: 'Desc',
        status: IConst.closed,
        expiresAt: DateTime.now().add(const Duration(days: 1)),
      );
      var taps = 0;

      await pumpPage(
        tester,
        item: item,
        bottomAction: const Text('Action'),
        onContentTap: () => taps++,
      );
      await tester.tap(find.text('content_action'), warnIfMissed: false);
      await tester.pump();

      expect(find.text('Closed'), findsOneWidget);
      expect(find.text('Action'), findsNothing);
      expect(taps, 0);
    },
  );

  testWidgets(
    'closes UI when expiresAt is in the past even if status is active',
    (tester) async {
      final item = _TestHomeItem(
        id: '2',
        title: 'Title',
        description: 'Desc',
        status: IConst.active,
        expiresAt: DateTime.now().subtract(const Duration(seconds: 1)),
      );
      var taps = 0;

      await pumpPage(
        tester,
        item: item,
        bottomAction: const Text('Action'),
        onContentTap: () => taps++,
      );
      await tester.tap(find.text('content_action'), warnIfMissed: false);
      await tester.pump();

      expect(find.text('Closed'), findsOneWidget);
      expect(find.text('Action'), findsNothing);
      expect(taps, 0);
    },
  );

  testWidgets(
    'keeps UI open when status is active and expiresAt is in future',
    (tester) async {
      final item = _TestHomeItem(
        id: '3',
        title: 'Title',
        description: 'Desc',
        status: IConst.active,
        expiresAt: DateTime.now().add(const Duration(days: 1)),
      );
      var taps = 0;

      await pumpPage(
        tester,
        item: item,
        bottomAction: const Text('Action'),
        onContentTap: () => taps++,
      );
      await tester.tap(find.text('content_action'));
      await tester.pump();

      expect(find.text('Closed'), findsNothing);
      expect(find.text('Action'), findsOneWidget);
      expect(taps, 1);
    },
  );
}
