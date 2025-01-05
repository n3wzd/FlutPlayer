import 'dart:async';
import './utils/audio_manager.dart';
import './utils/background_manager.dart';
import './utils/playlist.dart';
import './utils/database_manager.dart';
import './utils/audio_handler.dart';
import './utils/preference.dart';
import './utils/permission_handler.dart';
import './models/color.dart';

bool isFullScreen = false;
String currentVisualizerColor = 'ffffff';
double playListSavedScrollPosition = 0;

Future<void> initApp() async {
  await Preference.init();
  await DatabaseManager.instance.init();
  PermissionHandler.instance.init();
  AudioManager.instance.init();
  createAudioSerivce();
  await BackgroundManager.instance.init();
  BackgroundTransitionTimer.instance.init();
}

void setVisualizerColor() {
  String color = Preference.randomColorVisualizer ? getRandomColor() : (PlayList.instance.currentAudioColor ?? 'ffffff');
  color = color == 'null' ? 'ffffff' : color;
  currentVisualizerColor = color;
}
