import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:scalextric/components/translucent_button.dart';
import 'package:scalextric/pages/leaderboard_page.dart';
import 'package:scalextric/pages/login/qualifying_login.dart';
import 'package:scalextric/pages/login/race_login.dart';
import 'package:scalextric/state/rest_state.dart';

class ChooseModePage extends StatefulWidget {
  const ChooseModePage({super.key});
  static const String name = '/choseMode';

  @override
  State<ChooseModePage> createState() => _ChooseModePageState();
}

class _ChooseModePageState extends State<ChooseModePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RestState>(context, listen: false).getAllUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(120),
      child: Column(
        children: [
          const GameTitle(),
          Box(
            child: Row(
              spacing: 40,
              children: [
                Flexible(
                  child: TranslucentButton(
                    padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
                    onTap: () => context.go(QualifyingLoginPage.name),
                    child: const Column(
                      children: [
                        Text(
                          'Qualifying',
                          style: TextStyle(fontSize: 60, fontWeight: FontWeight.w800),
                        ),
                        Text(
                          '(Single Player)',
                          style: TextStyle(fontSize: 30, fontFamily: 'Titillium', fontWeight: FontWeight.w300),
                        ),
                      ],
                    ),
                  ),
                ),
                Flexible(
                  child: TranslucentButton(
                    padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
                    onTap: () => context.go(RaceLoginPage.name),
                    child: const Column(
                      children: [
                        Text(
                          'Race',
                          style: TextStyle(fontSize: 60, fontWeight: FontWeight.w800),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          '(Two Player)',
                          style: TextStyle(
                            fontSize: 30,
                            fontFamily: 'Titillium',
                            fontWeight: FontWeight.w300,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
