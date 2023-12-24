import 'dart:async';

class AudioStreamController {
  static final track = StreamController<void>.broadcast();
  static final playList = StreamController<void>.broadcast();
  static final loopMode = StreamController<void>.broadcast();
  static final playListOrderState = StreamController<void>.broadcast();
  static final visualizerColor = StreamController<void>.broadcast();
  static final backgroundFile = StreamController<void>.broadcast();
  static final imageBackgroundAnimation = StreamController<void>.broadcast();

  static final enabledVisualizer = StreamController<void>.broadcast();
  static final enabledBackground = StreamController<void>.broadcast();
  static final enabledNCSLogo = StreamController<void>.broadcast();
  static final enabledFullsccreen = StreamController<void>.broadcast();
}
