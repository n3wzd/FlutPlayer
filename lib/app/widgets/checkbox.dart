import 'package:flutter/material.dart';

import '../models/color.dart';

class CheckboxFactory {
  static Widget checkbox({
    required bool value,
    void Function(bool?)? onChanged,
  }) => Checkbox(
    checkColor: ColorPalette.white,
    fillColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.disabled)
          ? ColorPalette.disableGrey
          : ColorPalette.lightWine,
    ),
    value: value,
    onChanged: onChanged,
  );
}
