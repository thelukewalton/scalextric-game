import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:scalextric/components/id_card.dart';
import 'package:scalextric/models/scan_user_body.dart';

import 'package:scalextric/pages/qualifying/qualifying_start_page.dart';
import 'package:scalextric/state/dw_state.dart';
import 'package:scalextric/state/game_state.dart';
import 'package:scalextric/state/rest_state.dart';
import 'package:scalextric/state/ws_state.dart';
import 'package:scalextric_shared/shared.dart';

class QualifyingScanPage extends StatefulWidget {
  const QualifyingScanPage({super.key});
  static const name = '/qualifyingScanPage';

  @override
  State<QualifyingScanPage> createState() => _QualifyingScanPageState();
}

class _QualifyingScanPageState extends State<QualifyingScanPage> {
  final isChangingPage = false;

  Future<void> changePage() async {
    if (isChangingPage) return;
    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted && context.mounted) context.pushReplacement(QualifyingStartPage.name);
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DataWedgeState>().initScanner();
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();
    final wsState = context.read<WebSocketState>();

    if (gameState.loggedInUser != null && !wsState.connected) {
      wsState.connect();
    }
    if (gameState.loggedInUser != null && wsState.connected && !isChangingPage) {
      changePage();
    }

    return PopScope(
      onPopInvokedWithResult: (didPop, result) => context.read<DataWedgeState>().clear(),
      child: context.watch<RestState>().status == Status.unknown && !Provider.of<GameState>(context).isEmulator
          ? const Text('Unable to connect to server')
          : IdCard(
              title: gameState.loggedInUser != null
                  ? 'Welcome'
                  : 'Scan your ${context.read<GameState>().settings.scannedThingName} below',
              onTap: gameState.loggedInUser != null
                  ? () => context.go(QualifyingStartPage.name)
                  : Provider.of<GameState>(context).isEmulator
                      ? () => context
                          .read<RestState>()
                          .postUser(ScanUserBody('marc', 'ilton', 'ingerland', 'marc@linton.com'))
                      : context.read<DataWedgeState>().scanBarcode,
              data: gameState.loggedInUser,
            ),
    );
  }
}
