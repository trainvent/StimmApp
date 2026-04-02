import 'package:flutter/widgets.dart';

class WebAdSenseFrame extends StatelessWidget {
  const WebAdSenseFrame({super.key, required this.adSlot, this.height = 96});

  final String adSlot;
  final double height;

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
