import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:scalextric/components/leaderboard.dart';
import 'package:scalextric/components/passcode.dart';
import 'package:scalextric/components/translucent_button.dart';
import 'package:scalextric/pages/login/chose_mode_page.dart';
import 'package:scalextric/pages/qualifying/qualifying_scan_page.dart';
import 'package:scalextric/pages/race/race_scan_page.dart';
import 'package:scalextric/state/dw_state.dart';
import 'package:scalextric/state/game_state.dart';
import 'package:scalextric/state/rest_state.dart';
import 'package:scalextric/state/ws_state.dart';
import 'package:scalextric_shared/shared.dart';
import 'package:shimmer/shimmer.dart';
import 'package:zeta_flutter/zeta_flutter.dart';

class LeaderBoardsPage extends StatefulWidget {
  const LeaderBoardsPage({super.key});
  static const String name = '/leaderboards';

  @override
  State<LeaderBoardsPage> createState() => _LeaderBoardsPageState();
}

class _LeaderBoardsPageState extends State<LeaderBoardsPage> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      Provider.of<DataWedgeState>(context, listen: false).clear();
      Provider.of<RestState>(context, listen: false)
        ..clear()
        ..reset();
      Provider.of<WebSocketState>(context, listen: false).clear();
      Provider.of<GameState>(context, listen: false)
        ..clear()
        ..sendProperties();
      context.read<DataWedgeState>().initScanner(redirect: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<RestState, GameState>(
      builder: (context, state, gameState, _) {
        return Stack(
          children: [
            Positioned(
              bottom: 10,
              right: 10,
              child: GestureDetector(
                onLongPress: () {
                  showDialog<void>(context: context, builder: (_) => const Passcode());
                },
                child: Icon(
                  ZetaIcons.settings,
                  color: Zeta.of(context).colors.mainInverse.withAlpha(0.2 * 255 ~/ 1),
                  size: 60,
                ),
              ),
            ),
            GestureDetector(
              onTap: gameState.settings.useBarcodesForUsers &&
                      (state.status == Status.race || state.status == Status.qualifying)
                  ? () => context.push(state.status == Status.race ? RaceScanPage.name : QualifyingScanPage.name)
                  : null,
              child: PopScope(
                canPop: false,
                child: Padding(
                  padding: const EdgeInsets.only(top: 20, left: 80, right: 80, bottom: 20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(child: GameTitle()),
                          if (gameState.settings.useBarcodesForUsers)
                            Row(
                              children: [
                                const Text('Qualifying'),
                                ZetaSwitch(
                                  value: state.status == Status.race,
                                  onChanged: (x) {
                                    if (x != null) {
                                      state.resetStatus(status: x ? Status.race : Status.qualifying);
                                      context.read<DataWedgeState>().initScanner(redirect: true);
                                    }
                                  },
                                ),
                                const Text('Race'),
                              ],
                            ),
                        ],
                      ),
                      Expanded(
                        child: Box(
                          child: Column(
                            spacing: 30,
                            children: [
                              Expanded(
                                child: Row(
                                  spacing: 30,
                                  children: [
                                    Expanded(
                                      flex: 5,
                                      child: state.overallLeaderboard == null
                                          ? const Center(child: CircularProgressIndicator())
                                          : const Leaderboard(),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: state.lapLeaderboard == null
                                          ? const Center(child: CircularProgressIndicator())
                                          : const Leaderboard(lapType: LapType.lap),
                                    ),
                                  ],
                                ),
                              ),
                              if (!gameState.settings.useBarcodesForUsers && state.status != Status.unknown)
                                Row(
                                  children: [
                                    Expanded(
                                      child: TranslucentButton(
                                        child: const Text(
                                          'New Game',
                                          style: TextStyle(
                                            fontSize: 40,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        onTap: () => context.go(ChooseModePage.name),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                      if (state.status == Status.unknown)
                        const Nothing()
                      else if (gameState.settings.useBarcodesForUsers)
                        Shimmer.fromColors(
                          baseColor: Colors.white,
                          highlightColor: Colors.grey,
                          period: const Duration(milliseconds: 2500),
                          child: Text(
                            'To start a new game, scan your ${context.watch<GameState>().settings.scannedThingName} below or tap the screen',
                            style: const TextStyle(color: Colors.white, fontSize: 24),
                          ).paddingTop(40),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class Box extends StatelessWidget {
  const Box({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Durations.short4,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 28),
      decoration: ShapeDecoration(
        gradient: LinearGradient(
          begin: const Alignment(0.93, -0.36),
          end: const Alignment(-0.93, 0.36),
          colors: [
            Colors.black.withAlpha(0.3 * 255 ~/ 1),
            Colors.black.withAlpha(0.1 * 255 ~/ 1),
          ],
        ),
        shape: RoundedRectangleBorder(
          side: BorderSide(color: Colors.white.withAlpha(0.3 * 255 ~/ 1)),
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
        shadows: const [
          BoxShadow(
            color: Color(0x19000000),
            blurRadius: 120,
            offset: Offset(0, 61.34),
          ),
        ],
      ),
      child: child,
    );
  }
}

class GameTitle extends StatelessWidget {
  const GameTitle({super.key, this.isExpanded = true});
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameState>();
    final container = Hero(
      tag: 'game-title',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 6, left: 4),
            decoration: const ShapeDecoration(
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  width: 8,
                  strokeAlign: BorderSide.strokeAlignCenter,
                  color: Colors.white,
                ),
                borderRadius: BorderRadius.only(topLeft: Radius.circular(34), topRight: Radius.circular(34)),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(32, 16, 32, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SvgPicture.asset('assets/zebra-word.svg', height: 60),
                  Text(
                    '${DateTime.now().year} ${Provider.of<GameState>(context).settings.eventName.trim()} Grand Prix',
                    style: const TextStyle(
                      fontSize: 42,
                      color: Colors.white,
                      fontFamily: 'F1',
                      fontWeight: FontWeight.w800,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (state.settings.brandImage.isNotEmpty)
            Image.file(
              File(state.settings.brandImage),
              height: 160,
            ).paddingEnd(80),
        ],
      ),
    );

    return isExpanded
        ? Row(
            children: [
              Expanded(
                flex: 2,
                child: container,
              ),
              if (state.settings.brandImage.isEmpty) const Expanded(child: Nothing()),
            ],
          )
        : container;
  }
}
