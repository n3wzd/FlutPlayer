import 'package:flutter/material.dart';

import '../models/color.dart';

class SwitchMaker {
  static switchWidget({required bool value, onChanged}) => Switch(
        value: value,
        activeColor: ColorPalette.lightWine,
        onChanged: onChanged,
      );
}
