import 'package:flutter/material.dart';

import '../style/color.dart';

class SliderMaker {
  static normal(
          {required double value,
          required double max,
          double? min,
          ValueChanged<double>? onChanged,
          ValueChanged<double>? onChangeEnd,
          int? divisions,
          bool showLabel = false,
          bool useOverlayColor = true}) =>
      ThemeMaker.slider(
        Slider(
          value: value,
          max: max,
          min: min ?? 0,
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
          divisions: divisions,
          label: showLabel ? value.round().toString() : null,
        ),
        useOverlayColor: useOverlayColor,
      );

  static range(
          {required RangeValues values,
          required double max,
          double? min,
          ValueChanged<RangeValues>? onChanged,
          ValueChanged<RangeValues>? onChangeEnd,
          int? divisions,
          bool showLabel = false,
          bool useOverlayColor = true}) =>
      ThemeMaker.slider(
        RangeSlider(
          values: values,
          max: max,
          min: min ?? 0,
          onChanged: onChanged,
          onChangeEnd: onChangeEnd,
          activeColor: ColorMaker.purple,
          inactiveColor: ColorMaker.lightGrey,
          overlayColor:
              MaterialStateProperty.resolveWith((Set<MaterialState> states) {
            if (states.contains(MaterialState.hovered)) {
              return ColorMaker.overlayHoveredPurple;
            }
            return ColorMaker.transparent;
          }),
          divisions: divisions,
          labels: showLabel
              ? RangeLabels(
                  values.start.round().toString(),
                  values.end.round().toString(),
                )
              : null,
        ),
        useOverlayColor: useOverlayColor,
      );
}

class ThemeMaker {
  static slider(Widget slider, {bool useOverlayColor = true}) => SliderTheme(
        data: useOverlayColor
            ? const SliderThemeData()
            : SliderThemeData(
                overlayShape: SliderComponentShape.noOverlay,
              ),
        child: slider,
      );
}
