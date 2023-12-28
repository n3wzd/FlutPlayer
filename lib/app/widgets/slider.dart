import 'package:flutter/material.dart';

import '../models/color.dart';

class SliderFactory {
  static slider(
          {required double value,
          required double max,
          double? min,
          ValueChanged<double>? onChanged,
          ValueChanged<double>? onChangeEnd,
          int? divisions,
          bool showLabel = false,
          bool useOverlayColor = true}) =>
      ThemeFactory.slider(
        Slider(
          value: value,
          max: max,
          min: min ?? 0,
          onChanged: onChanged,
          onChangeEnd: onChangeEnd,
          thumbColor: ColorPalette.purple,
          activeColor: ColorPalette.purple,
          inactiveColor: ColorPalette.lightGrey,
          overlayColor:
              MaterialStateProperty.resolveWith((Set<MaterialState> states) {
            if (states.contains(MaterialState.hovered)) {
              return ColorPalette.purple;
            }
            return ColorPalette.transparent;
          }),
          divisions: divisions,
          label: showLabel ? value.round().toString() : null,
        ),
        useOverlayColor: useOverlayColor,
      );

  static rangeSlider(
          {required RangeValues values,
          required double max,
          double? min,
          ValueChanged<RangeValues>? onChanged,
          ValueChanged<RangeValues>? onChangeEnd,
          int? divisions,
          bool showLabel = false,
          bool useOverlayColor = true}) =>
      ThemeFactory.slider(
        RangeSlider(
          values: values,
          max: max,
          min: min ?? 0,
          onChanged: onChanged,
          onChangeEnd: onChangeEnd,
          activeColor: ColorPalette.purple,
          inactiveColor: ColorPalette.lightGrey,
          overlayColor:
              MaterialStateProperty.resolveWith((Set<MaterialState> states) {
            if (states.contains(MaterialState.hovered)) {
              return ColorPalette.purple;
            }
            return ColorPalette.transparent;
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

class ThemeFactory {
  static slider(Widget slider, {bool useOverlayColor = true}) => SliderTheme(
        data: useOverlayColor
            ? const SliderThemeData()
            : SliderThemeData(
                overlayShape: SliderComponentShape.noOverlay,
              ),
        child: slider,
      );
}
