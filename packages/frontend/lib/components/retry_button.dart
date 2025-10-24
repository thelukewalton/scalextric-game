import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:scalextric/components/translucent_button.dart';
import 'package:scalextric/state/game_state.dart';
import 'package:scalextric/state/rest_state.dart';
import 'package:scalextric/state/ws_state.dart';
import 'package:scalextric_shared/models/status.dart';

class RetryButton extends StatelessWidget {
  const RetryButton({super.key, required this.isRace});
  final bool isRace;

  @override
  Widget build(BuildContext context) {
    return Consumer3<WebSocketState, RestState, GameState>(
      builder: (context, webSocketState, restState, gameState, _) {
        return TranslucentButton(
          onTap: () {
            final users = [...gameState.racers];
            if (!isRace && gameState.loggedInUser == null) {
              // Shouldn't be possible to get here, but just in case
              context.go('/');
              return;
            } else {
              webSocketState.clearData();
              restState.reset();
              if (!isRace) {
                restState.loginUser(gameState.loggedInUser!, skipToPlay: true);
              } else {
                gameState.clear();

                restState
                  ..status = Status.race
                  ..loginUser(users.first)
                  ..loginUser(users.last);
              }
            }
          },
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 32),
            child: Text(
              'Retry?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w300,
              ),
            ),
          ),
        );
      },
    );
  }
}
