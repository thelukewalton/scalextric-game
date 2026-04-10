import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:scalextric/pages/settings/settings_page.dart';
import 'package:scalextric/state/game_state.dart';
import 'package:zeta_flutter/zeta_flutter.dart';

class Passcode extends StatefulWidget {
  const Passcode({super.key, this.setNew = false});

  final bool setNew;

  @override
  State<Passcode> createState() => _PasscodeState();
}

class _PasscodeState extends State<Passcode> {
  String enteredPasscode = '';
  bool incorrect = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Center(
          child: Container(
            color: Colors.black,
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                SizedBox(
                  width: 250,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '* ' * enteredPasscode.length,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 48,
                            color: incorrect ? Colors.red : Colors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.backspace, color: Colors.white),
                        onPressed: () {
                          if (enteredPasscode.isNotEmpty) {
                            enteredPasscode = enteredPasscode.substring(0, enteredPasscode.length - 1);
                            incorrect = false;
                            setState(() {});
                          }
                        },
                      ),
                    ],
                  ),
                ).paddingVertical(40),
                ZetaThemeOverride(
                  themeMode: ThemeMode.dark,
                  builder: (context) {
                    return ZetaDialPad(
                      onNumber: (value) {
                        enteredPasscode += value;
                        incorrect = false;
                        setState(() {});
                      },
                    );
                  },
                ),
                ZetaButton(
                  label: 'Enter',
                  onPressed: () async {
                    if (widget.setNew && enteredPasscode.length > 1) {
                      context.read<GameState>().settings =
                          context.read<GameState>().settings.copyWith(passcode: int.parse(enteredPasscode));
                      await context.read<GameState>().settings.toSavedPreferences();
                      if (mounted && context.mounted) {
                        Navigator.of(context).pop();
                      }
                      return;
                    }
                    if (enteredPasscode == context.read<GameState>().settings.passcode.toString()) {
                      context.go(SettingsPage.name);
                    } else {
                      incorrect = true;
                      setState(() {});
                      Future.delayed(const Duration(milliseconds: 500), () {
                        setState(() {
                          enteredPasscode = '';
                          incorrect = false;
                        });
                      });
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
