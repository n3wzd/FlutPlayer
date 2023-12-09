import 'package:flutter/material.dart';

import '../utils/preference.dart';
import './stream_builder.dart';
import '../global.dart' as global;

class OptionalVisibility {
  static fullScreen(BuildContext context, Widget child) =>
      AudioStreamBuilder.enabledFullsccreen(
        (context, data) => Visibility(
          visible: !global.isFullScreen,
          child: child,
        ),
      );

  static background(BuildContext context, Widget child) =>
      AudioStreamBuilder.enabledBackground(
        (context, data) => Visibility(
          visible: Preference.enableBackground,
          child: child,
        ),
      );

  static logoNCS(BuildContext context, Widget child) =>
      AudioStreamBuilder.enabledNCSLogo(
        (context, data) => Visibility(
          visible: Preference.enableNCSLogo,
          child: child,
        ),
      );

  static visualizer(BuildContext context, Widget child) =>
      AudioStreamBuilder.enabledVisualizer(
        (context, data) => Visibility(
          visible: Preference.enableVisualizer,
          child: child,
        ),
      );
}
