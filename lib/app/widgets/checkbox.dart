import 'package:flutter/material.dart';

import '../models/color.dart';

class CheckboxFactory {
  static checkbox({required bool value, void Function(bool?)? onChanged}) =>
      Checkbox(
        checkColor: ColorPalette.white,
        fillColor: MaterialStateProperty.resolveWith((states) =>
            states.contains(MaterialState.disabled)
                ? ColorPalette.disableGrey
                : ColorPalette.lightWine),
        value: value,
        onChanged: onChanged,
      );
}
