import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scalextric/components/live_timing.dart';

import 'package:scalextric/state/rest_state.dart';
import 'package:scalextric_shared/shared.dart';

class RacePage extends StatelessWidget {
  const RacePage({super.key});
  static const String name = '/racePage';

  @override
  Widget build(BuildContext context) {
    if (context.read<RestState>().status != Status.race) {
      context.read<RestState>().resetStatus(status: Status.race);
    }
    return const Row(
      children: [
        Expanded(child: LiveTiming(index: 1)),
        Expanded(child: LiveTiming(index: 2)),
      ],
    );
  }
}
