import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scalextric/state/game_state.dart';
import 'package:scalextric/state/ws_state.dart';

class PracticeCountdownPage extends StatelessWidget {
  const PracticeCountdownPage({super.key});
  static const name = '/practiceCountdown';

  @override
  Widget build(BuildContext context) {
    return Consumer<WebSocketState>(
      builder: (context, state, child) => GestureDetector(
        onTap: Provider.of<GameState>(context).isEmulator ? () => state.fakeLapTime() : null,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(60),
            child: Text(
              '${state.practiceLapsRemainingString} PRACTICE LAP${state.practiceLapsRemainingString == '1' ? '' : 'S'} TO GO',
              style: TextStyle(
                fontSize: 150,
                fontWeight: FontWeight.w500,
                shadows: <Shadow>[
                  Shadow(
                    offset: const Offset(0, 4),
                    blurRadius: 4,
                    color: Colors.black.withAlpha(0.25 * 255 ~/ 1),
                  ),
                ],
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
