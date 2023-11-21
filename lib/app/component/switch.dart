import 'package:flutter/material.dart';

import '../style/color.dart';

class SwitchMaker {
  static normal({required bool value, onChanged}) => Switch(
        value: value,
        activeColor: ColorMaker.lightWine,
        onChanged: onChanged,
      );
}
