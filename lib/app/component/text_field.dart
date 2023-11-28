import 'package:flutter/material.dart';

import '../style/color.dart';

class TextFieldMaker {
  static normal({void Function(String)? onChanged}) => TextField(
        onChanged: onChanged,
        decoration: DecorationMaker.textField(),
      );
}

class DecorationMaker {
  static textField() => const InputDecoration(
        filled: true,
        fillColor: ColorMaker.white,
        isDense: true,
        contentPadding: EdgeInsets.all(10),
      );
}
