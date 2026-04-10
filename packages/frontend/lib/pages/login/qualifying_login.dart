import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:scalextric/components/translucent_button.dart';
import 'package:scalextric/pages/leaderboard_page.dart';
import 'package:scalextric/pages/login/user_name_field.dart';
import 'package:scalextric/state/game_state.dart';
import 'package:scalextric/state/rest_state.dart';
import 'package:scalextric_shared/models/user.dart';
import 'package:zeta_flutter/zeta_flutter.dart';

class QualifyingLoginPage extends StatefulWidget {
  const QualifyingLoginPage({super.key});
  static const String name = '/qualifyingLogin';

  @override
  State<QualifyingLoginPage> createState() => _QualifyingLoginPageState();
}

class _QualifyingLoginPageState extends State<QualifyingLoginPage> {
  final TextEditingController controller = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Consumer<RestState>(
      builder: (context, restState, child) {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(120),
            child: Column(
              children: [
                Hero(
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
                            borderRadius:
                                BorderRadius.only(topLeft: Radius.circular(34), topRight: Radius.circular(34)),
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
                      if (Provider.of<GameState>(context).settings.brandImage.isNotEmpty)
                        Image.file(
                          File(Provider.of<GameState>(context).settings.brandImage),
                          height: 160,
                        ).paddingEnd(80),
                    ],
                  ),
                ),
                Box(
                  child: Column(
                    spacing: 40,
                    children: [
                      UserNameField(
                        controller: controller,
                        callback: () => setState(() {}),
                      ),
                      SizedBox(
                        width: 250,
                        height: 125,
                        child: TranslucentButton(
                          onTap: controller.text.isEmpty
                              ? null
                              : () {
                                  restState.loginUser(
                                    User(id: controller.text, name: controller.text),
                                  );
                                },
                          child: const Text(
                            'Start',
                            style: TextStyle(fontSize: 60, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
