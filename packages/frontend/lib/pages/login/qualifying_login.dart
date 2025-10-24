import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scalextric/components/translucent_button.dart';
import 'package:scalextric/pages/leaderboard_page.dart';
import 'package:scalextric/pages/login/user_name_field.dart';
import 'package:scalextric/state/rest_state.dart';
import 'package:scalextric_shared/models/user.dart';

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
