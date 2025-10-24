import 'dart:ui';

import 'package:flutter/material.dart';

class TranslucentCard extends StatelessWidget {
  const TranslucentCard({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(0.2 * 255 ~/ 1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withAlpha(0.6 * 255 ~/ 1), width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: child,
        ),
      ),
    );
  }
}
