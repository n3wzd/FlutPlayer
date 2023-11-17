import 'package:flutter/material.dart';

import '../style/color.dart';

class DecorationMaker {
  static textField() => const InputDecoration(
        filled: true,
        fillColor: ColorMaker.white,
        isDense: true,
        contentPadding: EdgeInsets.all(10),
      );
}
