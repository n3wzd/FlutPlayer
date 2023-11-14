import 'package:flutter/material.dart';

import '../style/color.dart';

class SliderMaker {
  static normal(
          {required value,
          required max,
          required onChanged,
          onChangeEnd,
          useOverlayColor = true}) =>
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
