import 'package:flutter/material.dart';

class LemmImage extends StatelessWidget {
  const LemmImage({
    super.key,
    this.assetPath = 'assets/images/Lemm_teaching.png',
  });

  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: MediaQuery.sizeOf(context).width / 3,
      fit: BoxFit.contain,
    );
  }
}
