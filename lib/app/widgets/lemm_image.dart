import 'package:flutter/material.dart';

class LemmImage extends StatelessWidget {
  const LemmImage({
    super.key,
    this.assetPath = 'assets/images/Lemm_teaching.png',
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.excludeFromSemantics = false,
  });

  final String assetPath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final bool excludeFromSemantics;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
      excludeFromSemantics: excludeFromSemantics,
    );
  }
}
