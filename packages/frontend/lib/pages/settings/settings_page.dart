import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:scalextric/components/passcode.dart';
import 'package:scalextric/pages/leaderboard_page.dart';
import 'package:scalextric/pages/settings/game_settings_page.dart';
import 'package:scalextric/pages/settings/technical_settings_page.dart';
import 'package:scalextric/pages/settings/tools_page.dart';
import 'package:zeta_flutter/zeta_flutter.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});
  static const String name = '/settings';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 120, 20, 0),
      child: Column(
        children: [
          Expanded(
            child: Column(
              spacing: 120,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ZetaButton.outlineSubtle(
                      size: ZetaWidgetSize.large,
                      label: 'Game Settings',
                      onPressed: () => context.push(GameSettingsPage.name),
                    ),
                    ZetaButton.outlineSubtle(
                      size: ZetaWidgetSize.large,
                      label: 'Technical Settings',
                      onPressed: () => context.push(TechnicalSettingsPage.name),
                    ),
                    ZetaButton.outlineSubtle(
                      size: ZetaWidgetSize.large,
                      label: 'Tools',
                      onPressed: () => context.push(ToolsPage.name),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ZetaButton.negative(
                      label: 'Maintenance Mode',
                      size: ZetaWidgetSize.large,
                      onPressed: () => context.push('/maintenance'),
                    ),
                  ],
                ),
                ZetaButton.text(
                  label: 'Change settings passcode',
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (_) => const Passcode(setNew: true),
                    );
                  },
                ),
              ],
            ),
          ),
          ZetaButton.positive(
            size: ZetaWidgetSize.large,
            label: 'Return to game',
            onPressed: () => context.push(LeaderBoardsPage.name),
          ),
        ],
      ),
    );
  }
}
