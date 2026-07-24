import 'package:flutter/material.dart';
import 'package:stimmapp/core/constants/dimension_constants.dart';

class AppBottomBarButtons extends StatelessWidget {
  const AppBottomBarButtons({
    super.key,
    required this.buttons,
    required this.body,
    this.appBar,
  });
  final List<Widget> buttons;
  final Widget body;
  final PreferredSizeWidget? appBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      body: body,
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: DConst.pad50,
          horizontal: DConst.pad25,
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: buttons),
      ),
    );
  }
}
