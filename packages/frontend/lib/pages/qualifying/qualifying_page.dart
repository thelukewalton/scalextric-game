import 'package:flutter/material.dart';
import 'package:scalextric/components/lap_counter.dart';
import 'package:scalextric/components/live_timing.dart';
import 'package:zeta_flutter/zeta_flutter.dart';

class QualifyingPage extends StatelessWidget {
  const QualifyingPage({super.key});
  static const name = '/qualifying';

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(flex: 6, child: const LapCounter(showImage: true).paddingTop(90).paddingBottom(34)),
        Expanded(flex: 7, child: const LiveTiming().paddingTop(90)),
      ],
    );
  }
}
