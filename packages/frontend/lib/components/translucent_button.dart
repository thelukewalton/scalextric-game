import 'package:flutter/material.dart';
import 'package:scalextric/components/card.dart';

class TranslucentButton extends StatelessWidget {
  const TranslucentButton({super.key, required this.child, this.onTap, this.padding});

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return TranslucentCard(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: padding ?? const EdgeInsets.all(10),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}
