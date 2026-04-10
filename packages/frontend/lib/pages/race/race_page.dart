import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scalextric/components/card.dart';
import 'package:scalextric/components/live_timing.dart';
import 'package:scalextric/components/mv_image.dart';
import 'package:scalextric/state/game_state.dart';
import 'package:scalextric/state/rest_state.dart';
import 'package:scalextric_shared/shared.dart';
import 'package:zeta_flutter/zeta_flutter.dart';
import 'package:zeta_flutter/zeta_utils.dart';

class RacePage extends StatelessWidget {
  const RacePage({super.key});
  static const String name = '/racePage';

  @override
  Widget build(BuildContext context) {
    if (context.read<RestState>().status != Status.race) {
      context.read<RestState>().resetStatus(status: Status.race);
    }
    return Stack(
      children: [
        if (context.read<GameState>().settings.useFSCamera)
          const Center(
            child: SizedBox(
              width: 500,
              height: 310,
              child: TranslucentCard(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 40),
                  child: MVImage(size: 260, raceMode: true),
                ),
              ),
            ),
          ).paddingBottom(235),
        const Row(
          children: [
            Expanded(child: LiveTiming(index: 1, left: true)),
            Expanded(child: LiveTiming(index: 2, left: false)),
          ],
        ),
      ],
    );
  }
}
