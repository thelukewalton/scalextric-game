import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:scalextric/state/game_state.dart';
import 'package:scalextric/state/rest_state.dart';
import 'package:scalextric/state/ws_state.dart';
import 'package:zeta_flutter/zeta_flutter.dart';

class RaceStartPage extends StatelessWidget {
  const RaceStartPage({super.key});
  static const name = '/raceStartPage';

  @override
  Widget build(BuildContext context) {
    final wsState = context.read<WebSocketState>();
    if (!wsState.connected) {
      wsState.connect();
    }

    return Consumer3<WebSocketState, GameState, RestState>(
      builder: (context, state, gameState, restState, _) {
        final isPlayer1 = state.raceCarIds.isEmpty;
        String? carImage;
        if (isPlayer1) {
          carImage = gameState.settings.carImage;
        } else {
          carImage = gameState.settings.secondCarImage;
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 100),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  Text(
                    context.watch<GameState>().racers[isPlayer1 ? 0 : 1].name,
                    style: const TextStyle(
                      fontSize: 110,
                      fontFamily: 'f1',
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Text(
                    'Place your car on the START',
                    style: TextStyle(
                      fontSize: 100,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              GestureDetector(
                onTap: gameState.isEmulator
                    ? () async {
                        restState
                          ..fakeRFID(
                            state.raceCarIds.isEmpty ? RestState.fakeCarId1 : RestState.fakeCarId2,
                            DateTime.now().subtract(const Duration(minutes: 10)),
                          )
                          ..fakeRFID(state.raceCarIds.isEmpty ? RestState.fakeCarId1 : RestState.fakeCarId2);
                      }
                    : null,
                child: carImage.isNotEmpty
                    ? SvgPicture.file(File(carImage), width: 200, height: 200)
                    : SvgPicture.asset('assets/car.svg', width: 200, height: 200),
              ),
            ].gap(40),
          ),
        );
      },
    );
  }
}
