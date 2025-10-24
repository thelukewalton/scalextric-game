import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scalextric/components/id_card.dart';
import 'package:scalextric/models/scan_user_body.dart';
import 'package:scalextric/pages/leaderboard_page.dart';
import 'package:scalextric/state/dw_state.dart';
import 'package:scalextric/state/game_state.dart';
import 'package:scalextric/state/rest_state.dart';
import 'package:scalextric_shared/shared.dart';

class RaceScanPage extends StatefulWidget {
  const RaceScanPage({super.key});
  static const name = '/raceScanPage';

  @override
  State<RaceScanPage> createState() => _RaceScanPageState();
}

class _RaceScanPageState extends State<RaceScanPage> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.read<GameState>().racers.isEmpty) {
        context.read<RestState>()
          ..clear()
          ..resetStatus(status: Status.race);

        context.read<DataWedgeState>()
          ..clear()
          ..initScanner();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, state, _) {
        return Padding(
          padding: const EdgeInsets.all(100),
          child: Column(
            children: [
              const GameTitle(),
              const SizedBox(height: 20),
              Box(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    IdCard(
                      onTap: state.isEmulator
                          ? () {
                              context.read<RestState>().postUser(ScanUserBody('Luke ', ' Walton', 'uk', 'email'));
                            }
                          : null,
                      data: state.racers.isNotEmpty ? state.racers[0] : null,
                      heroId: 'racer1',
                    ),
                    IdCard(
                      onTap: state.isEmulator
                          ? () {
                              context
                                  .read<RestState>()
                                  .postUser(ScanUserBody('Marcilton', 'Marcilton', 'ingerland', 'email2'));
                            }
                          : null,
                      data: state.racers.length > 1 ? state.racers[1] : null,
                      heroId: 'racer2',
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
