import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
            child: Row(
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
