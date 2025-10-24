import 'package:flutter/material.dart';

class SettingRow extends StatelessWidget {
  const SettingRow({
    super.key,
    required this.initialValue,
    required this.onSaved,
    required this.title,
    required this.icon,
    this.numeric = false,
  });
  final String initialValue;
  final FormFieldSetter<String> onSaved;
  final String title;
  final IconData icon;
  final bool numeric;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: TextFormField(
        onSaved: onSaved,
        initialValue: initialValue,
        textCapitalization: TextCapitalization.sentences,
        keyboardType: numeric ? const TextInputType.numberWithOptions(decimal: true) : null,
        style: const TextStyle(color: Colors.black),
        decoration: InputDecoration(
          fillColor: Colors.white,
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Colors.white),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Colors.blue),
          ),
        ),
        cursorColor: Colors.blue,
      ),
    );
  }
}
