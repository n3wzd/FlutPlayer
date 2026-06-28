import 'package:flutter/material.dart';

import '../utils/preference.dart';
import '../utils/background_manager.dart';
import './stream_builder.dart';
import '../app_state.dart';

class OptionalVisibility {
  static StreamBuilder<void> fullScreen(BuildContext context, Widget child) =>
      AudioStreamBuilder.enabledFullscreen(
        (context, data) =>
            Visibility(visible: !AppState.instance.isFullScreen, child: child),
      );

  static StreamBuilder<void> background(BuildContext context, Widget child) =>
      AudioStreamBuilder.enabledBackground(
        (context, data) =>
            Visibility(visible: Preference.enableBackground, child: child),
      );

  static StreamBuilder<void> logoNCS(BuildContext context, Widget child) =>
      AudioStreamBuilder.enabledNCSLogo(
        (context, data) => Visibility(
          visible:
              BackgroundManager.instance.currentNcsLogoOverride ??
              Preference.enableNCSLogo,
          child: child,
        ),
      );

  static StreamBuilder<void> visualizer(BuildContext context, Widget child) =>
      AudioStreamBuilder.enabledVisualizer(
        (context, data) => Visibility(
          visible:
              BackgroundManager.instance.currentVisualizerOverride ??
              Preference.enableVisualizer,
          child: child,
        ),
      );
}
