import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:stimmapp/app/widgets/slidable_widget.dart';

void main() {
  Future<void> pumpSlidable(
    WidgetTester tester, {
    bool showSwipeHint = false,
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
                showSwipeHint: showSwipeHint,
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

  testWidgets(
    'hint reveals left then right actions once without executing them',
    (tester) async {
      var actions = 0;
      await pumpSlidable(
        tester,
        showSwipeHint: true,
        onStartSwipe: () async => actions++,
        onEndSwipe: () async => actions++,
      );
      final tile = find.byType(AppSlidable);
      final originalBounds = tester.getRect(tile);
      final controller = tester
          .widget<Slidable>(find.byType(Slidable))
          .controller!;
      for (var frame = 0; frame < 80 && controller.ratio > -0.12; frame++) {
        await tester.pump(const Duration(milliseconds: 20));
      }
      expect(controller.ratio, inInclusiveRange(-0.145, -0.12));
      expect(find.text('Leave'), findsOneWidget);
      expect(tester.getRect(tile), originalBounds);
      for (var frame = 0; frame < 80 && controller.ratio < 0.12; frame++) {
        await tester.pump(const Duration(milliseconds: 20));
      }
      expect(controller.ratio, inInclusiveRange(0.12, 0.145));
      expect(find.text('Dashboard'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 220));
      await tester.pumpAndSettle();
      expect(controller.ratio, 0);
      expect(actions, 0);
      await pumpSlidable(
        tester,
        showSwipeHint: true,
        onStartSwipe: () async => actions++,
        onEndSwipe: () async => actions++,
      );
      await tester.pump(const Duration(seconds: 2));
      expect(controller.ratio, 0);
      expect(actions, 0);
    },
  );

  testWidgets('touching a tile cancels its pending hint', (tester) async {
    await pumpSlidable(
      tester,
      showSwipeHint: true,
      onStartSwipe: () async {},
      onEndSwipe: () async {},
    );
    await tester.tap(find.byType(AppSlidable));
    await tester.pump(const Duration(milliseconds: 600));
    expect(tester.widget<Slidable>(find.byType(Slidable)).controller!.ratio, 0);
    await tester.pumpAndSettle();
  });

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
