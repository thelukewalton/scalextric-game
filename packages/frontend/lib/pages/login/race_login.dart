import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:scalextric/components/translucent_button.dart';
import 'package:scalextric/pages/leaderboard_page.dart';
import 'package:scalextric/pages/login/user_name_field.dart';
import 'package:scalextric/state/game_state.dart';
import 'package:scalextric/state/rest_state.dart';
import 'package:scalextric_shared/models/status.dart';
import 'package:scalextric_shared/models/user.dart';

class RaceLoginPage extends StatefulWidget {
  const RaceLoginPage({super.key});
  static const String name = '/raceLoginPage';

  @override
  State<RaceLoginPage> createState() => _RaceLoginPageState();
}

class _RaceLoginPageState extends State<RaceLoginPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RestState>().resetStatus(status: Status.race);
    });
  }

  final controller1 = TextEditingController();
  final controller2 = TextEditingController();

  bool isPlayer1Ready = false;
  bool isPlayer2Ready = false;

  String? player1Error;
  String? player2Error;

  @override
  Widget build(BuildContext context) {
    return Consumer<RestState>(
      builder: (context, restState, _) {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(120),
            child: Column(
              children: [
                Row(
                  spacing: 40,
                  children: [
                    PlayerDialog(
                      controller: controller1,
                      isPlayerReady: isPlayer1Ready,
                      setState: () {
                        if (controller1.text == controller2.text) {
                          player1Error = 'Names must be different';
                          player2Error = 'Names must be different';
                        } else {
                          player1Error = null;
                          player2Error = null;
                        }
                        setState(() {});
                      },
                      error: player1Error,
                      otherValue: controller2.text,
                      readyCallback: () {
                        if (controller1.text == controller2.text) {
                          player1Error = 'Names must be different';
                          player2Error = 'Names must be different';
                        } else if (controller1.text.isEmpty) {
                          player1Error = 'Please enter a name';
                          player2Error = 'Please enter a name';
                        } else {
                          player1Error = null;
                          player2Error = null;
                        }
                        isPlayer1Ready = true;
                        restState.loginUser(User(id: controller1.text, name: controller1.text));
                        if (isPlayer2Ready) {
                          restState.loginUser(User(id: controller2.text, name: controller2.text));
                        }
                        setState(() {});
                      },
                      playerNumber: 1,
                    ),
                    PlayerDialog(
                      controller: controller2,
                      isPlayerReady: isPlayer2Ready,
                      otherValue: controller1.text,
                      error: player2Error,
                      setState: () {
                        if (controller1.text == controller2.text) {
                          player1Error = 'Names must be different';
                          player2Error = 'Names must be different';
                        } else {
                          player1Error = null;
                          player2Error = null;
                        }
                        setState(() {});
                      },
                      readyCallback: () {
                        if (controller1.text == controller2.text) {
                          player1Error = 'Names must be different';
                          player2Error = 'Names must be different';

                          return;
                        } else if (controller1.text.isEmpty) {
                          player1Error = 'Please enter a name';
                          player2Error = 'Please enter a name';
                          return;
                        } else {
                          player1Error = null;
                          player2Error = null;
                        }
                        isPlayer2Ready = true;
                        if (isPlayer1Ready) {
                          restState.loginUser(User(id: controller2.text, name: controller2.text));
                        }
                        setState(() {});
                      },
                      playerNumber: 2,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class PlayerDialog extends StatelessWidget {
  const PlayerDialog({
    super.key,
    required this.controller,
    required this.isPlayerReady,
    required this.setState,
    required this.readyCallback,
    required this.playerNumber,
    this.error,
    this.otherValue,
  });

  final TextEditingController controller;
  final bool isPlayerReady;
  final VoidCallback setState;
  final VoidCallback readyCallback;
  final int playerNumber;
  final String? otherValue;
  final String? error;

  @override
  Widget build(BuildContext context) {
    String carImage;
    if (playerNumber == 1) {
      carImage = Provider.of<GameState>(context, listen: false).settings.carImage;
    } else {
      carImage = Provider.of<GameState>(context, listen: false).settings.secondCarImage;
    }

    return Expanded(
      child: Stack(
        children: [
          if (isPlayerReady)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(128),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          if (isPlayerReady)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              child: Center(child: Text('Player $playerNumber ready', style: const TextStyle(fontSize: 48))),
            ),
          Opacity(
            opacity: isPlayerReady ? 0.3 : 1,
            child: Box(
              child: Column(
                spacing: 40,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Player $playerNumber', style: const TextStyle(fontSize: 40)),
                      if (carImage.isNotEmpty)
                        SvgPicture.file(File(carImage), height: 60)
                      else
                        SvgPicture.asset('assets/car.svg', width: 60),
                    ],
                  ),
                  UserNameField(
                    controller: controller,
                    callback: setState,
                    enabled: !isPlayerReady,
                    otherValue: otherValue,
                    error: error,
                  ),
                  SizedBox(
                    width: 250,
                    height: 125,
                    child: TranslucentButton(
                      onTap: controller.text.isEmpty || isPlayerReady ? null : readyCallback,
                      child: const Text(
                        'Ready',
                        style: TextStyle(fontSize: 60, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
