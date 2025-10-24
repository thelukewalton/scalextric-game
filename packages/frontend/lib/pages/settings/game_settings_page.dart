import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:scalextric/components/settings_row.dart';
import 'package:scalextric/pages/settings/settings_page.dart';

import 'package:scalextric/state/game_state.dart';
import 'package:zeta_flutter/zeta_flutter.dart';

class GameSettingsPage extends StatelessWidget {
  const GameSettingsPage({super.key, this.settings});
  static const String name = '/game-settings';

  final GameSettings? settings;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(80, 40, 80, 0),
      child: _SettingsPageBody(settings: settings ?? context.read<GameState>().settings),
    );
  }
}

class _SettingsPageBody extends StatefulWidget {
  const _SettingsPageBody({required this.settings});

  final GameSettings settings;
  @override
  State<_SettingsPageBody> createState() => _SettingsPageBodyState();
}

class _SettingsPageBodyState extends State<_SettingsPageBody> {
  final _formKey = GlobalKey<FormState>();
  late GameSettings settings;

  @override
  void initState() {
    super.initState();
    settings = widget.settings;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, state, _) {
        return Builder(
          builder: (context) {
            return Column(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Game Settings',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Expanded(
                                child: ListView(
                                  children: [
                                    SettingRow(
                                      onSaved: (value) {
                                        if (value != null) {
                                          settings = settings.copyWith(circuitLength: double.tryParse(value));
                                        }
                                      },
                                      initialValue: settings.circuitLength.toString(),
                                      title: 'Track length',
                                      icon: Icons.timeline,
                                      numeric: true,
                                    ),
                                    SettingRow(
                                      onSaved: (value) {
                                        if (value != null) {
                                          settings = settings.copyWith(practiceLaps: int.tryParse(value));
                                        }
                                      },
                                      initialValue: settings.practiceLaps.toString(),
                                      title: 'Practice laps',
                                      icon: Icons.time_to_leave,
                                      numeric: true,
                                    ),
                                    SettingRow(
                                      icon: Icons.timelapse,
                                      title: 'Qualifying laps',
                                      onSaved: (value) {
                                        if (value != null) {
                                          settings = settings.copyWith(qualifyingLaps: int.tryParse(value));
                                        }
                                      },
                                      initialValue: settings.qualifyingLaps.toString(),
                                      numeric: true,
                                    ),
                                    SettingRow(
                                      icon: Icons.car_crash,
                                      title: 'Race laps',
                                      onSaved: (value) {
                                        if (value != null) {
                                          settings = settings.copyWith(raceLaps: int.tryParse(value));
                                        }
                                      },
                                      initialValue: settings.raceLaps.toString(),
                                      numeric: true,
                                    ),
                                    SettingRow(
                                      icon: Icons.lightbulb,
                                      title: 'Race light amount',
                                      onSaved: (value) {
                                        if (value != null) {
                                          settings = settings.copyWith(raceLights: int.tryParse(value));
                                        }
                                      },
                                      initialValue: settings.raceLights.toString(),
                                      numeric: true,
                                    ),
                                    SettingRow(
                                      icon: Icons.lightbulb,
                                      title: 'Scanned thing name',
                                      onSaved: (value) {
                                        if (value != null) {
                                          settings = settings.copyWith(scannedThingName: value);
                                        }
                                      },
                                      initialValue: settings.scannedThingName,
                                    ),
                                    SettingRow(
                                      icon: Icons.lightbulb,
                                      title: 'Event name - In format YYYY NAME GRAND PRIX',
                                      onSaved: (value) {
                                        if (value != null) {
                                          settings = settings.copyWith(eventName: value);
                                        }
                                      },
                                      initialValue: settings.eventName,
                                    ),
                                    Row(
                                      children: [
                                        const Text(
                                          'Use barcodes for user sign in',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        ZetaSwitch(
                                          value: settings.useBarcodesForUsers,
                                          onChanged: (value) {
                                            settings = settings.copyWith(useBarcodesForUsers: value);
                                            setState(() {});
                                          },
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        const Text(
                                          'Sound effects',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        ZetaSwitch(
                                          value: settings.soundEffects,
                                          onChanged: (value) {
                                            settings = settings.copyWith(soundEffects: value);
                                            setState(() {});
                                          },
                                        ),
                                      ],
                                    ),
                                  ].gap(20),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (settings != state.settings) ...[
                        const Text(
                          'Unsaved changes',
                          style: TextStyle(color: Colors.red),
                        ),
                        const SizedBox(width: 20),
                      ],
                      ZetaButton.outlineSubtle(
                        label: 'Cancel',
                        size: ZetaWidgetSize.large,
                        onPressed: () async {
                          if (context.mounted) context.pushReplacement(SettingsPage.name);
                        },
                      ),
                      ZetaButton.positive(
                        size: ZetaWidgetSize.large,
                        label: 'Save',
                        onPressed: () async {
                          _formKey.currentState?.save();
                          state.settings = settings;
                          await state.settings.toSavedPreferences();
                          if (context.mounted) {
                            context.pushReplacement(SettingsPage.name);
                          }
                        },
                      ),
                    ].gap(40),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
