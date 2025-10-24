import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:scalextric/components/settings_row.dart';
import 'package:scalextric/pages/leaderboard_page.dart';
import 'package:scalextric/pages/login/qualifying_login.dart';
import 'package:scalextric/pages/qualifying/practice_coutdown_page.dart';
import 'package:scalextric/pages/qualifying/practice_instructions_page.dart';
import 'package:scalextric/pages/qualifying/qualifying_finish_page.dart';
import 'package:scalextric/pages/qualifying/qualifying_page.dart';
import 'package:scalextric/pages/qualifying/qualifying_scan_page.dart';
import 'package:scalextric/pages/qualifying/qualifying_start_page.dart';
import 'package:scalextric/pages/race/race_page.dart';
import 'package:scalextric/pages/settings/settings_page.dart';
import 'package:scalextric/state/game_state.dart';
import 'package:zeta_flutter/zeta_flutter.dart';

class TechnicalSettingsPage extends StatelessWidget {
  const TechnicalSettingsPage({super.key, this.settings});
  static const String name = '/technical-settings';

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
                    'Technical Settings',
                    style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
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
                                      icon: ZetaIcons.uhf_rfid,
                                      initialValue: settings.rfidReaderUrl,
                                      onSaved: (value) {
                                        if (value != null) {
                                          settings = settings.copyWith(rfidReaderUrl: value);
                                        }
                                      },
                                      title: 'RFID Reader IP address',
                                    ),
                                    SettingRow(
                                      icon: Icons.https,
                                      title: 'Server IP address',
                                      onSaved: (value) {
                                        if (value != null) {
                                          settings = settings.copyWith(serverUrl: value);
                                        }
                                      },
                                      initialValue: settings.serverUrl,
                                    ),
                                    SettingRow(
                                      icon: Icons.api,
                                      title: 'Rest port',
                                      onSaved: (value) {
                                        if (value != null) {
                                          settings = settings.copyWith(restPort: value);
                                        }
                                      },
                                      initialValue: settings.restPort,
                                      numeric: true,
                                    ),
                                    SettingRow(
                                      initialValue: settings.websocketPort,
                                      numeric: true,
                                      onSaved: (value) {
                                        if (value != null) {
                                          settings = settings.copyWith(websocketPort: value);
                                        }
                                      },
                                      title: 'WebSocket port',
                                      icon: Icons.web_asset,
                                    ),
                                    // SettingRow(
                                    //   initialValue: settings.minLapTime.toString(),
                                    //   onSaved: (value) {
                                    //     if (value != null) {
                                    //       settings = settings.copyWith(minLapTime: int.tryParse(value));
                                    //     }
                                    //   },
                                    //   numeric: true,
                                    //   title: 'Minimum lap time (in seconds)',
                                    //   icon: Icons.timer,

                                    // ),
                                    Row(
                                      children: [
                                        const Text('RFID Toggleable', style: TextStyle(color: Colors.white)),
                                        ZetaSwitch(
                                          value: settings.rfidToggleable,
                                          onChanged: (value) {
                                            settings = settings.copyWith(rfidToggleable: value);
                                            setState(() {});
                                          },
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 20),
                                      width: 200,
                                      child: Row(
                                        children: [
                                          ZetaGroupButton.dropdown(
                                            label: 'Go to page',
                                            rounded: true,
                                            icon: Icons.find_in_page_rounded,
                                            items: [
                                              ZetaDropdownItem(label: 'Leaderboard Page', value: 'lp'),
                                              ZetaDropdownItem(label: 'Scan Id Page', value: 'si'),
                                              ZetaDropdownItem(label: 'Practice Instructions Page', value: 'pi'),
                                              ZetaDropdownItem(label: 'Car Start Page', value: 'cs'),
                                              ZetaDropdownItem(label: 'Practice Countdown Page', value: 'pc'),
                                              ZetaDropdownItem(label: 'Qualifying Page', value: 'q'),
                                              ZetaDropdownItem(label: 'Finish Page', value: 'f'),
                                              ZetaDropdownItem(label: 'Race Page', value: 'rp'),
                                              ZetaDropdownItem(label: 'Qualifying Login Page', value: 'ql'),
                                            ],
                                            onChange: (item) {
                                              switch (item.value) {
                                                case 'lp':
                                                  context.go(LeaderBoardsPage.name);
                                                  break;
                                                case 'si':
                                                  context.go(QualifyingScanPage.name);
                                                  break;
                                                case 'pi':
                                                  context.go(PracticeInstructionsPage.name);
                                                  break;
                                                case 'cs':
                                                  context.go(QualifyingStartPage.name);
                                                case 'pc':
                                                  context.go(PracticeCountdownPage.name);
                                                  break;
                                                case 'q':
                                                  context.go(QualifyingPage.name);
                                                  break;
                                                case 'f':
                                                  context.go(QualifyingFinishPage.name);
                                                  break;
                                                case 'rp':
                                                  context.go(RacePage.name);
                                                  break;
                                                case 'ql':
                                                  context.go(QualifyingLoginPage.name);
                                                  break;
                                                default:
                                                  break;
                                              }
                                            },
                                          ),
                                        ],
                                      ),
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
                          state.sendProperties();
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
