import 'package:flutter/material.dart';

class TeachingLemmImage extends StatelessWidget {
  const TeachingLemmImage({super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/Lemm_teaching.png',
      width: MediaQuery.sizeOf(context).width / 3,
      fit: BoxFit.contain,
    );
  }
}
