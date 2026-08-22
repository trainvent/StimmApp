import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:stimmapp/app/widgets/slidable_widget.dart';

void main() {
  Future<void> pumpSlidable(
    WidgetTester tester, {
    required Future<void> Function() onStartSwipe,
    required Future<void> Function() onEndSwipe,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 400,
              child: AppSlidable(
                key: const Key('slidable'),
                startAction: const AppSlidableAction(
                  icon: Icons.dashboard_outlined,
                  label: 'Dashboard',
                ),
                endAction: const AppSlidableAction(
                  icon: Icons.logout,
                  label: 'Leave',
                ),
                onStartSwipe: onStartSwipe,
                onEndSwipe: onEndSwipe,
                child: const SizedBox(height: 80),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> dragRow(WidgetTester tester, Offset offset) async {
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(AppSlidable)),
    );
    await gesture.moveBy(offset);
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
  }

  testWidgets('start swipe action triggers after 30 percent drag', (
    tester,
  ) async {
    var startSwipeActions = 0;

    await pumpSlidable(
      tester,
      onStartSwipe: () async => startSwipeActions++,
      onEndSwipe: () async {},
    );

    expect(tester.getSize(find.byType(AppSlidable)), const Size(400, 80));
    await dragRow(tester, const Offset(124, 0));

    expect(startSwipeActions, 1);
  });

  testWidgets('end swipe action triggers after 30 percent drag', (
    tester,
  ) async {
    var endSwipeActions = 0;

    await pumpSlidable(
      tester,
      onStartSwipe: () async {},
      onEndSwipe: () async => endSwipeActions++,
    );
    await dragRow(tester, const Offset(-124, 0));

    expect(endSwipeActions, 1);
  });

  testWidgets('incomplete swipe snaps closed without an action', (
    tester,
  ) async {
    var swipeActions = 0;

    await pumpSlidable(
      tester,
      onStartSwipe: () async => swipeActions++,
      onEndSwipe: () async => swipeActions++,
    );
    await dragRow(tester, const Offset(-80, 0));

    final slidable = tester.widget<Slidable>(find.byType(Slidable));
    expect(swipeActions, 0);
    expect(slidable.controller!.ratio, 0);
  });

  testWidgets('closing an open pane does not trigger the opposite action', (
    tester,
  ) async {
    var startSwipeActions = 0;

    await pumpSlidable(
      tester,
      onStartSwipe: () async => startSwipeActions++,
      onEndSwipe: () async {},
    );
    final slidable = tester.widget<Slidable>(find.byType(Slidable));
    await slidable.controller!.openEndActionPane(duration: Duration.zero);
    await tester.pump();

    await dragRow(tester, const Offset(124, 0));

    expect(startSwipeActions, 0);
    expect(slidable.controller!.ratio, 0);
  });
}
