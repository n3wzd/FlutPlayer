import 'package:flutter/material.dart';

import '../models/color.dart';

class TextFieldFactory {
  static textField({void Function(String)? onChanged}) => TextField(
        onChanged: onChanged,
        decoration: DecorationFactory.textField(),
      );
}

class DecorationFactory {
  static textField() => const InputDecoration(
        filled: true,
        fillColor: ColorPalette.white,
        isDense: true,
        contentPadding: EdgeInsets.all(10),
      );
}
