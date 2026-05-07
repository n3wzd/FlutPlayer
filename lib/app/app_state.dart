import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import './models/color.dart';
import './utils/playlist.dart';
import './utils/preference.dart';
import './utils/stream_controller.dart';

class AppState extends ChangeNotifier {
  AppState._();

  static final AppState instance = AppState._();

  bool _isFullScreen = false;
  String _visualizerColor = 'ffffff';
  double playListSavedScrollPosition = 0;

  bool get isFullScreen => _isFullScreen;
  String get visualizerColor => _visualizerColor;

  Future<void> toggleFullScreen() async {
    _isFullScreen = !_isFullScreen;
    if (_isFullScreen) {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
      );
    }
    notifyListeners();
    AudioStreamController.enabledFullscreen.add(null);
  }

  void updateVisualizerColor() {
    var color = Preference.randomColorVisualizer
        ? getRandomColor()
        : (PlayList.instance.currentAudioColor ?? 'ffffff');
    color = color == 'null' ? 'ffffff' : color;
    _visualizerColor = color;
    notifyListeners();
  }
}
