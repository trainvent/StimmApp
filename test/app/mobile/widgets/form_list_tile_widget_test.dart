import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stimmapp/app/widgets/form_list_tile_widget.dart';

void main() {
  Widget buildTile({Widget? thumbnail}) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 400,
          child: FormListTileWidget(
            title: 'A title that can occupy two lines when needed',
            description: 'A description that provides some useful context.',
            count: 12,
            countIcon: Icons.how_to_vote,
            thumbnail: thumbnail,
            status: const Text('Status'),
            onTap: () {},
          ),
        ),
      ),
    );
  }

  testWidgets('keeps the count on the bottom row with a thumbnail', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildTile(thumbnail: const ColoredBox(color: Colors.orange)),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('12'), findsOneWidget);

    final countBottom = tester.getBottomRight(find.text('12')).dy;
    final statusBottom = tester.getBottomLeft(find.text('Status')).dy;
    expect(countBottom, closeTo(statusBottom, 1));
  });

  testWidgets('uses the same bottom-row alignment without a thumbnail', (
    tester,
  ) async {
    await tester.pumpWidget(buildTile());

    expect(tester.takeException(), isNull);

    final countBottom = tester.getBottomRight(find.text('12')).dy;
    final statusBottom = tester.getBottomLeft(find.text('Status')).dy;
    expect(countBottom, closeTo(statusBottom, 1));
  });
}
