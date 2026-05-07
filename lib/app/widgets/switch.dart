import 'package:flutter/material.dart';

import '../models/color.dart';

class SwitchFactory {
  static Widget normal({required bool value, ValueChanged<bool>? onChanged}) =>
      Switch(
        value: value,
        activeThumbColor: ColorPalette.lightWine,
        onChanged: onChanged,
      );
}
