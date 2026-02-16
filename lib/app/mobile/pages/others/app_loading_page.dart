import 'package:flutter/material.dart';
import 'package:stimmapp/app/mobile/widgets/triangle_loading_indicator.dart';

class AppLoadingPage extends StatelessWidget {
  const AppLoadingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: TriangleLoadingIndicator(
          size: 56,
          trianglesPerCycle: 6,
          buildDuration: Duration(milliseconds: 1300),
          zoomDuration: Duration(milliseconds: 800),
          strokeWidth: 2.1,
        ),
      ),
    );
  }
}
