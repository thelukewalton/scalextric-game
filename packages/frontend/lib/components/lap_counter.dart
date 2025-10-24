import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scalextric/components/card.dart';
import 'package:scalextric/components/lap_row_item.dart';
import 'package:scalextric/state/game_state.dart';
import 'package:scalextric/state/ws_state.dart';
import 'package:zeta_flutter/zeta_flutter.dart';

class LapCounter extends StatelessWidget {
  const LapCounter({super.key, this.index});
  final int? index;

  @override
  Widget build(BuildContext context) {
    return Consumer2<WebSocketState, GameState>(
      builder: (context, state, gameState, _) {
        return Hero(
          tag: 'lap-counter-$index',
          child: TranslucentCard(
            child: Padding(
              padding: const EdgeInsets.all(24).copyWith(right: 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                    index != null ? gameState.racers[index! - 1].name : 'LAP TIMES',
                    style: const TextStyle(
                      fontSize: 40,
                      color: Colors.white,
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Center(
                        child: Column(
                          children: List.generate(
                            index != null ? gameState.settings.raceLaps : gameState.settings.qualifyingLaps,
                            (lap) => LapRowItem(lap: lap + 1, index: index),
                          ).gap(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
