import 'package:flutter/material.dart';

import '../style/color.dart';

class SliderMaker {
  static normal(
          {required double value,
          required double max,
          required ValueChanged<double> onChanged,
          ValueChanged<double>? onChangeEnd,
          bool useOverlayColor = true}) =>
      SliderTheme(
        data: useOverlayColor
            ? const SliderThemeData()
            : SliderThemeData(
                overlayShape: SliderComponentShape.noOverlay,
              ),
        child: Slider(
          value: value,
          max: max,
          onChanged: onChanged,
          onChangeEnd: onChangeEnd,
          thumbColor: ColorMaker.purple,
          activeColor: ColorMaker.purple,
          inactiveColor: ColorMaker.lightGrey,
          overlayColor:
              MaterialStateProperty.resolveWith((Set<MaterialState> states) {
            if (states.contains(MaterialState.hovered)) {
              return ColorMaker.overlayHoveredPurple;
            }
            return ColorMaker.transparent;
          }),
        ),
      );
}
