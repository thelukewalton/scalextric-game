import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:scalextric/components/formatted_duration.dart';
import 'package:scalextric/components/lap_counter.dart';
import 'package:scalextric/components/leaderboard.dart';
import 'package:scalextric/components/reset_timer.dart';
import 'package:scalextric/components/retry_button.dart';
import 'package:scalextric/pages/leaderboard_page.dart';
import 'package:scalextric/state/game_state.dart';
import 'package:scalextric/state/ws_state.dart';

class QualifyingFinishPage extends StatefulWidget {
  const QualifyingFinishPage({super.key});
  static const name = '/qualifyingFinish';

  @override
  State<QualifyingFinishPage> createState() => _QualifyingFinishPageState();
}

class _QualifyingFinishPageState extends State<QualifyingFinishPage> {
  final player = AudioPlayer();

  // @override
  // void initState() {
  //   super.initState();
  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //     if (context.mounted && mounted && context.read<GameState>().settings.soundEffects) {
  //       player.play(AssetSource('vroom.mp3'));
  //     }
  //   });
  // }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resetTimerKey = GlobalKey<ResetTimerState>();

    return Consumer2<WebSocketState, GameState>(
      builder: (context, state, gameState, _) {
        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'FINISH',
                                style: TextStyle(
                                  fontSize: 80,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => resetTimerKey.currentState?.resetTimer(),
                                  child: const LapCounter(),
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const RetryButton(isRace: false),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          const Text(
                                            'Total time: ',
                                            style: TextStyle(fontSize: 36),
                                          ),
                                          FormattedDuration(
                                            Duration(milliseconds: state.overallTime),
                                            style: const TextStyle(fontSize: 36),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          Text(
                                            'Attempts: ${(gameState.loggedInUser?.attempts ?? 0) + 1}',
                                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w300),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 7,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(48, 0, 68, 0),
                      child: GestureDetector(
                        onTap: () => context.go(LeaderBoardsPage.name),
                        child: const Leaderboard(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 0,
              width: MediaQuery.of(context).size.width,
              child: ResetTimer(
                key: resetTimerKey,
                onFinish: () => context.go(LeaderBoardsPage.name),
              ),
            ),
          ],
        );
      },
    );
  }
}
