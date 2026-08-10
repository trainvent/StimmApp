import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stimmapp/app/widgets/snackbar_utils.dart';
import 'package:stimmapp/app_entry.dart';

class _ShowSnackBarDuringBuild extends StatefulWidget {
  const _ShowSnackBarDuringBuild();

  @override
  State<_ShowSnackBarDuringBuild> createState() =>
      _ShowSnackBarDuringBuildState();
}

class _ShowSnackBarDuringBuildState extends State<_ShowSnackBarDuringBuild> {
  bool _requested = false;

  @override
  Widget build(BuildContext context) {
    if (!_requested) {
      _requested = true;
      showSuccessSnackBar('Sync enabled');
    }
    return const Scaffold(body: SizedBox.expand());
  }
}

void main() {
  testWidgets('defers snackbar changes requested during build', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: const _ShowSnackBarDuringBuild(),
      ),
    );
    await tester.pump();

    expect(find.text('Sync enabled'), findsOneWidget);
    expect(tester.takeException(), isNull);

    navigatorKey.currentState!.push(
      MaterialPageRoute<void>(builder: (_) => const Scaffold()),
    );
    await tester.pump();
    navigatorKey.currentState!.pop();
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
