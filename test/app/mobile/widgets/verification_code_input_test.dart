import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pinput/pinput.dart';
import 'package:stimmapp/app/widgets/verification_code_input.dart';

void main() {
  Widget buildInput({
    required TextEditingController controller,
    ValueChanged<String>? onCompleted,
    double width = 400,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            child: VerificationCodeInput(
              key: const Key('verification-code'),
              controller: controller,
              onCompleted: onCompleted,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('uses Pinput and completes a six-digit code', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    String? completedCode;

    await tester.pumpWidget(
      buildInput(
        controller: controller,
        onCompleted: (code) => completedCode = code,
      ),
    );

    expect(find.byType(Pinput), findsOneWidget);

    await tester.enterText(find.byType(EditableText), '123456');
    await tester.pump();

    expect(controller.text, '123456');
    expect(completedCode, '123456');
  });

  testWidgets('filters non-digits and fits on a narrow screen', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(buildInput(controller: controller, width: 260));

    await tester.enterText(find.byType(EditableText), '12ab34');
    await tester.pump();

    expect(controller.text, '1234');
    expect(tester.takeException(), isNull);
  });
}
