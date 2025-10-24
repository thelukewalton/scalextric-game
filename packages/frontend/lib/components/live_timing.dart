import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:scalextric/components/card.dart';
import 'package:scalextric/components/dashboard.dart';
import 'package:scalextric/components/formatted_duration.dart';
import 'package:scalextric/state/game_state.dart';
import 'package:scalextric/state/ws_state.dart';
import 'package:zeta_flutter/zeta_flutter.dart';

class LiveTiming extends StatelessWidget {
  const LiveTiming({super.key, this.index});

  final int? index;

  @override
  Widget build(BuildContext context) {
    String carImage;
    if (index != null && index! == 2) {
      carImage = Provider.of<GameState>(context, listen: false).settings.secondCarImage;
    } else {
      carImage = Provider.of<GameState>(context, listen: false).settings.carImage;
    }
    return Consumer2<WebSocketState, GameState>(
      builder: (context, state, gameState, _) {
        final String userName;

        if (gameState.loggedInUser != null) {
          userName = gameState.loggedInUser!.name;
        } else if (gameState.racers.isNotEmpty && index != null && index! - 1 < gameState.racers.length) {
          userName = gameState.racers[index! - 1].name;
        } else {
          userName = 'Player ${index == null ? '1' : index.toString()}';
        }

        return Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              FittedBox(
                child: Hero(
                  tag: 'name-$index',
                  child: Text(
                    userName.trim(),
                    style: const TextStyle(fontSize: 40),
                  ),
                ),
              ),
              TranslucentCard(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          if (gameState.settings.trackImage.isNotEmpty)
                            SvgPicture.file(
                              File(gameState.settings.trackImage),
                              height: gameState.isEmulator ? 160 : 180,
                            )
                          else
                            SvgPicture.asset(
                              'assets/zebrahead.svg',
                              height: gameState.isEmulator ? 160 : 180,
                            ),
                          if (carImage.isNotEmpty)
                            SvgPicture.file(File(carImage), height: 100)
                          else
                            SvgPicture.asset('assets/car.svg', height: 100),
                        ],
                      ),
                      if (gameState.isEmulator)
                        ZetaButton(
                          label: 'Fake lap',
                          onPressed: () => state.fakeLapTime(index),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(top: 30),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Text(
                              'LAP ${(index != null ? state.getCurrentLapFromIndex(index!) : state.currentLap).clamp(1, state.maxLaps)}/${state.totalLaps}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w300,
                                fontSize: 48,
                                color: Colors.white,
                              ),
                            ),
                            Column(
                              children: [
                                const Text(
                                  'FASTEST LAP',
                                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w500, color: Colors.white),
                                ),
                                FormattedDuration(
                                  Duration(
                                    milliseconds:
                                        index != null ? state.getFastestLapFromIndex(index!) : state.fastestLap ?? 0,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Dashboard(index: index),
            ],
          ),
        );
      },
    );
  }
}
