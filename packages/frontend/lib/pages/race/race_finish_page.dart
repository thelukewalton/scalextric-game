import 'dart:io';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:scalextric/components/lap_counter.dart';
import 'package:scalextric/components/reset_timer.dart';
import 'package:scalextric/components/retry_button.dart';
import 'package:scalextric/pages/leaderboard_page.dart';
import 'package:scalextric/state/game_state.dart';
import 'package:scalextric/state/ws_state.dart';
import 'package:zeta_flutter/zeta_flutter.dart';

class RaceFinishPage extends StatefulWidget {
  const RaceFinishPage({super.key});
  static const String name = '/raceFinishPage';

  @override
  State<RaceFinishPage> createState() => _RaceFinishPageState();
}

class _RaceFinishPageState extends State<RaceFinishPage> {
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
  Widget build(BuildContext context) {
    final resetTimerKey = GlobalKey<ResetTimerState>();
    return GestureDetector(
      onTap: () => context.go(LeaderBoardsPage.name),
      child: Stack(
        children: [
          Consumer<WebSocketState>(
            builder: (context, state, _) {
              String carImage;
              if (state.winningIndex == 0) {
                carImage = Provider.of<GameState>(context, listen: false).settings.carImage;
              } else {
                carImage = Provider.of<GameState>(context, listen: false).settings.secondCarImage;
              }
              return Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        const Text(
                          'WINNER',
                          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 100),
                        ),
                        ConfettiName(name: state.raceWinner!.name, index: state.winningIndex),
                        if (carImage.isNotEmpty)
                          SvgPicture.file(File(carImage), height: 200)
                        else
                          SvgPicture.asset('assets/car.svg', width: 200),
                        const SizedBox(height: 40),
                        const RetryButton(isRace: true),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: GestureDetector(
                        onTap: () => resetTimerKey.currentState!.resetTimer(),
                        child: Column(
                          children: [
                            const Expanded(child: LapCounter(index: 1)),
                            const Expanded(child: LapCounter(index: 2)),
                          ].gap(40),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 80),
                ],
              );
            },
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ResetTimer(
              key: resetTimerKey,
              onFinish: () => context.go(LeaderBoardsPage.name),
            ),
          ),
        ],
      ),
    );
  }
}

class ConfettiName extends StatefulWidget {
  const ConfettiName({
    super.key,
    required this.name,
    required this.index,
  });

  final String name;
  final int index;

  @override
  State<ConfettiName> createState() => _ConfettiNameState();
}

class _ConfettiNameState extends State<ConfettiName> {
  late ConfettiController _controllerCenter;

  @override
  void initState() {
    super.initState();
    _controllerCenter = ConfettiController(duration: const Duration(seconds: 10));
    _controllerCenter.play();
  }

  @override
  void dispose() {
    _controllerCenter.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (_controllerCenter.state == ConfettiControllerState.playing) {
          _controllerCenter.stop();
        } else {
          _controllerCenter.play();
        }
      },
      child: Stack(
        children: [
          Center(
            child: ConfettiWidget(
              confettiController: _controllerCenter,
              colors: const [Colors.black, Colors.white],
              // canvas: Size.infinite,
              blastDirection: -pi / 2, numberOfParticles: 1000,
            ),
          ),
          Hero(
            tag: 'name-${widget.index}',
            child: Center(
              child: Text(
                widget.name,
                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 100),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
