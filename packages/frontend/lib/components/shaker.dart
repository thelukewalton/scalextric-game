import 'package:awesome_shake_widget/enum/shake_preset.dart';
import 'package:awesome_shake_widget/shake_widget.dart';
import 'package:flutter/material.dart';

class Shaker extends StatefulWidget {
  const Shaker({super.key, required this.child});
  final Widget child;

  @override
  State<Shaker> createState() => _ShakerState();
}

class _ShakerState extends State<Shaker> {
  final key = GlobalKey<ShakeWidgetState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerShakeRandomly();
    });
  }

  Future<void> _triggerShakeRandomly() async {
    while (mounted) {
      await Future<void>.delayed(Duration(milliseconds: 1800 + (400 * (DateTime.now().millisecondsSinceEpoch % 5))));
      await key.currentState?.shake();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ShakeWidget(
      preset: ShakePreset.light,
      duration: const Duration(milliseconds: 500),
      key: key,
      child: widget.child,
    );
  }
}
