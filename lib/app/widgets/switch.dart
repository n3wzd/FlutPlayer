import 'package:flutter/material.dart';

import '../models/color.dart';

class SwitchFactory {
  static normal({required bool value, onChanged}) => Switch(
        value: value,
        activeColor: ColorPalette.lightWine,
        onChanged: onChanged,
      );
}
