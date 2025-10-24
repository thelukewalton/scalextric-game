import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scalextric/components/formatted_duration.dart';
import 'package:scalextric/components/leaderboard_row.dart';
import 'package:scalextric/state/ws_state.dart';
import 'package:zeta_flutter/zeta_flutter.dart';

class LapRowItem extends StatelessWidget {
  const LapRowItem({super.key, required this.lap, this.index});

  final int lap;
  final int? index;

  @override
  Widget build(BuildContext context) {
    return Consumer<WebSocketState>(
      builder: (context, state, child) {
        final time = index != null ? state.raceLapTime(lap, index!) : state.qualifyingLapTime(lap);

        return LeaderboardRow(
          index: lap,
          time: 0,
          leadingColor: state.getLapColor(time, lap, index),
          child: double.tryParse(time) != null
              ? FormattedDuration(
                  Duration(milliseconds: double.parse(time).toInt()),
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w300, fontFamily: 'Titillium'),
                )
              : const Nothing(),
        );
      },
    );
  }
}
