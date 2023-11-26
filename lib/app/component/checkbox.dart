import 'package:flutter/material.dart';

import '../style/color.dart';

class CheckboxMaker {
  static normal({required bool value, void Function(bool?)? onChanged}) =>
      Checkbox(
        checkColor: ColorMaker.white,
        fillColor: MaterialStateProperty.resolveWith((states) =>
            states.contains(MaterialState.disabled)
                ? ColorMaker.disableGrey
                : ColorMaker.lightWine),
        value: value,
        onChanged: onChanged,
      );
}
