import 'dart:typed_data';
import 'package:flutter/material.dart';

class GroupAvatar extends StatelessWidget {
  const GroupAvatar({super.key, this.url, this.bytes, this.size = 40});
  final String? url;
  final Uint8List? bytes;
  final double size;

  @override
  Widget build(BuildContext context) {
    final fallback = ColoredBox(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Center(
        child: Icon(
          Icons.groups_2_outlined,
          size: size * 0.55,
          color: Theme.of(context).colorScheme.onSecondaryContainer,
        ),
      ),
    );
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: ClipOval(
          child: bytes != null
              ? Image.memory(
                  bytes!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => fallback,
                )
              : url != null && url!.isNotEmpty
              ? Image.network(
                  url!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => fallback,
                  frameBuilder: (_, child, frame, _) =>
                      frame == null ? fallback : child,
                )
              : fallback,
        ),
      ),
    );
  }
}
