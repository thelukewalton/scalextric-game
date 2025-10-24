import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:provider/provider.dart';
import 'package:scalextric/state/game_state.dart';
import 'package:scalextric/state/rest_state.dart';
import 'package:scalextric_shared/models/user.dart';
import 'package:zeta_flutter/zeta_flutter.dart';

class UserNameField extends StatelessWidget {
  const UserNameField({
    super.key,
    required this.controller,
    this.callback,
    this.enabled = true,
    this.otherValue,
    this.error,
  });

  final TextEditingController controller;
  final VoidCallback? callback;
  final bool enabled;
  final String? otherValue;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Consumer2<RestState, GameState>(
      builder: (context, restState, gameState, _) {
        return TypeAheadField<User>(
          controller: controller,
          suggestionsCallback: (search) {
            final allOptions = restState.allUsers.toSet().toList();
            search = search.toLowerCase();
            if (otherValue != null && otherValue!.isNotEmpty) {
              allOptions.removeWhere((e) {
                return e.name.toLowerCase() == otherValue!.toLowerCase();
              });
            }
            if (search.isNotEmpty) {
              return allOptions.where((e) {
                return e.name.toLowerCase().contains(search);
              }).toList();
            } else {
              return allOptions;
            }
          },
          builder: (context, controller, focusNode) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              textCapitalization: TextCapitalization.sentences,
              autofocus: enabled,
              onChanged: callback != null ? (_) => callback!() : null,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp('[0-9a-zA-Z -]')),
                if (gameState.racers.isNotEmpty) FilteringTextInputFormatter.deny(gameState.racers.first.name),
              ],
              style: const TextStyle(
                fontSize: 34,
                fontFamily: 'Titillium',
                fontWeight: FontWeight.w300,
                color: Colors.white,
              ),
              enabled: enabled,
              decoration: InputDecoration(
                errorText: error,
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.black.withAlpha(100),
                labelText: 'Enter your name',
                labelStyle: const TextStyle(
                  fontSize: 28,
                  fontFamily: 'Titillium',
                  fontWeight: FontWeight.w300,
                  color: Colors.white,
                ),
              ),
            );
          },
          itemBuilder: (context, user) {
            return ListTile(
              tileColor: Colors.black.withAlpha(245),
              textColor: Colors.white.withAlpha(200),
              title: Text(user.name),
            );
          },
          onSelected: (user) {
            controller.text = user.name;
            callback?.call();
          },
          emptyBuilder: (_) => const Nothing(),
        );
      },
    );
  }
}
