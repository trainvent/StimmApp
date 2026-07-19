import 'package:flutter/material.dart';
import 'package:trainvent_general/trainvent_general.dart';

class AppLoadingPage extends StatelessWidget {
  const AppLoadingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: TriangleLoadingIndicator(
          size: 56,
        ),
      ),
    );
  }
}
