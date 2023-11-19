import 'package:flutter/material.dart';

import './color.dart';

class DecorationMaker {
  static textField() => const InputDecoration(
        filled: true,
        fillColor: ColorMaker.white,
        isDense: true,
        contentPadding: EdgeInsets.all(10),
      );
}
