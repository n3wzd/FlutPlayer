import 'dart:async';

class AudioStreamController {
  static final track = StreamController<void>.broadcast();
  static final playList = StreamController<void>.broadcast();
  static final loopMode = StreamController<void>.broadcast();
  static final playListOrderState = StreamController<void>.broadcast();
  static final visualizerColor = StreamController<void>.broadcast();
  static final backgroundFile = StreamController<void>.broadcast();
  static final imageBackgroundAnimation = StreamController<void>.broadcast();
  static final mashupButton = StreamController<void>.broadcast();

  static final enabledVisualizer = StreamController<void>.broadcast();
  static final enabledBackground = StreamController<void>.broadcast();
  static final enabledNCSLogo = StreamController<void>.broadcast();
  static final enabledFullscreen = StreamController<void>.broadcast();

  static void emitTrackChanged() => track.add(null);
  static void emitPlayListChanged() => playList.add(null);
  static void emitLoopModeChanged() => loopMode.add(null);
  static void emitPlayListOrderChanged() => playListOrderState.add(null);
  static void emitVisualizerColorChanged() => visualizerColor.add(null);
  static void emitBackgroundFileChanged() => backgroundFile.add(null);
  static void emitImageBackgroundAnimationChanged() =>
      imageBackgroundAnimation.add(null);
  static void emitMashupButtonChanged() => mashupButton.add(null);
  static void emitEnabledVisualizerChanged() => enabledVisualizer.add(null);
  static void emitEnabledBackgroundChanged() => enabledBackground.add(null);
  static void emitEnabledNCSLogoChanged() => enabledNCSLogo.add(null);
  static void emitEnabledFullscreenChanged() => enabledFullscreen.add(null);
}
