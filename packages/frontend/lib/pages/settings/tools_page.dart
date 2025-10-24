import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:scalextric/pages/settings/settings_page.dart';
import 'package:scalextric/state/game_state.dart';
import 'package:scalextric/state/rest_state.dart';
import 'package:zeta_flutter/zeta_flutter.dart';

class ToolsPage extends StatelessWidget {
  const ToolsPage({super.key, this.settings});
  static const String name = '/tools';

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
                    'Tools',
                    style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: Row(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              spacing: 28,
                              children: [
                                ZetaButton.outlineSubtle(
                                  size: ZetaWidgetSize.large,
                                  label: 'RFID Reset',
                                  onPressed: context.watch<RestState>().rfidResetting
                                      ? null
                                      : () async {
                                          await context.read<RestState>().resetRFID();
                                        },
                                ),
                                ZetaButton.outlineSubtle(
                                  size: ZetaWidgetSize.large,
                                  label: 'Save settings to JSON',
                                  onPressed: () async {
                                    _formKey.currentState?.save();
                                    state.settings = settings;
                                    await state.writeJson(settings);
                                  },
                                ),
                                ZetaButton.outlineSubtle(
                                  size: ZetaWidgetSize.large,
                                  label: 'Load settings from JSON',
                                  onPressed: () async {
                                    final newSettings = await GameSettings.fromJson();
                                    if (newSettings != null) {
                                      if (context.mounted) {
                                        context.pushReplacement(SettingsPage.name);
                                      }
                                    }
                                  },
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    ZetaButton.outlineSubtle(
                                      size: ZetaWidgetSize.large,
                                      label: 'Set background image',
                                      onPressed: () {
                                        FilePicker.platform.pickFiles(
                                          type: FileType.custom,
                                          allowedExtensions: ['jpg', 'jpeg', 'png'],
                                        ).then((value) {
                                          if (value != null) {
                                            setState(
                                              () => settings =
                                                  settings.copyWith(backgroundImage: value.files.single.path),
                                            );
                                          }
                                        });
                                      },
                                    ),
                                    ZetaButton.negative(
                                      size: ZetaWidgetSize.large,
                                      label: 'Clear background image',
                                      onPressed: settings.backgroundImage.isEmpty
                                          ? null
                                          : () => setState(() => settings = settings.copyWith(backgroundImage: '')),
                                    ),
                                    if (settings.backgroundImage.isEmpty)
                                      const SizedBox(width: 60, height: 60)
                                    else
                                      Image.file(File(settings.backgroundImage), height: 60),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    ZetaButton.outlineSubtle(
                                      size: ZetaWidgetSize.large,
                                      label: 'Set track image',
                                      onPressed: () {
                                        FilePicker.platform.pickFiles(
                                          type: FileType.custom,
                                          allowedExtensions: ['svg'],
                                        ).then((value) {
                                          if (value != null) {
                                            setState(
                                              () => settings = settings.copyWith(trackImage: value.files.single.path),
                                            );
                                          }
                                        });
                                      },
                                    ),
                                    ZetaButton.negative(
                                      size: ZetaWidgetSize.large,
                                      label: 'Clear track image',
                                      onPressed: settings.trackImage.isEmpty
                                          ? null
                                          : () => setState(() => settings = settings.copyWith(trackImage: '')),
                                    ),
                                    if (settings.trackImage.isEmpty)
                                      const SizedBox(width: 60, height: 60)
                                    else
                                      SvgPicture.file(File(settings.trackImage), height: 60),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    ZetaButton.outlineSubtle(
                                      size: ZetaWidgetSize.large,
                                      label: 'Set car 1 image',
                                      onPressed: () {
                                        FilePicker.platform.pickFiles(
                                          type: FileType.custom,
                                          allowedExtensions: ['svg'],
                                        ).then((value) {
                                          if (value != null) {
                                            setState(
                                              () => settings = settings.copyWith(carImage: value.files.single.path),
                                            );
                                          }
                                        });
                                      },
                                    ),
                                    ZetaButton.negative(
                                      size: ZetaWidgetSize.large,
                                      label: 'Clear car 1 image',
                                      onPressed: settings.carImage.isEmpty
                                          ? null
                                          : () => setState(() => settings = settings.copyWith(carImage: '')),
                                    ),
                                    if (settings.carImage.isEmpty)
                                      const SizedBox(width: 60, height: 60)
                                    else
                                      SvgPicture.file(File(settings.carImage), height: 60),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    ZetaButton.outlineSubtle(
                                      size: ZetaWidgetSize.large,
                                      label: 'Set car 2 image',
                                      onPressed: () {
                                        FilePicker.platform.pickFiles(
                                          type: FileType.custom,
                                          allowedExtensions: ['svg'],
                                        ).then((value) {
                                          if (value != null) {
                                            setState(
                                              () =>
                                                  settings = settings.copyWith(secondCarImage: value.files.single.path),
                                            );
                                          }
                                        });
                                      },
                                    ),
                                    ZetaButton.negative(
                                      size: ZetaWidgetSize.large,
                                      label: 'Clear car 2 image',
                                      onPressed: settings.secondCarImage.isEmpty
                                          ? null
                                          : () => setState(() => settings = settings.copyWith(secondCarImage: '')),
                                    ),
                                    if (settings.secondCarImage.isEmpty)
                                      const SizedBox(width: 60)
                                    else
                                      SvgPicture.file(File(settings.secondCarImage), height: 60),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    ZetaButton.outlineSubtle(
                                      size: ZetaWidgetSize.large,
                                      label: 'Set brand image',
                                      onPressed: () {
                                        FilePicker.platform.pickFiles(
                                          type: FileType.custom,
                                          allowedExtensions: ['jpg', 'jpeg', 'png'],
                                        ).then((value) {
                                          if (value != null) {
                                            setState(
                                              () => settings = settings.copyWith(brandImage: value.files.single.path),
                                            );
                                          }
                                        });
                                      },
                                    ),
                                    ZetaButton.negative(
                                      size: ZetaWidgetSize.large,
                                      label: 'Clear brand image',
                                      onPressed: settings.brandImage.isEmpty
                                          ? null
                                          : () => setState(() => settings = settings.copyWith(brandImage: '')),
                                    ),
                                    if (settings.brandImage.isEmpty)
                                      const SizedBox(width: 60)
                                    else
                                      Image.file(File(settings.brandImage), height: 60),
                                  ],
                                ),
                              ],
                            ),
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
