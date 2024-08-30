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

void initApp() async {
  await Preference.init();
  DatabaseManager.instance.init();
  PermissionHandler.instance.init();
  AudioManager.instance.init();
  createAudioSerivce();
  BackgroundManager.instance.init();
}

void setVisualizerColor() {
  String color = Preference.randomColorVisualizer ? getRandomColor() : (PlayList.instance.currentAudioColor ?? 'ffffff');
  color = color == 'null' ? 'ffffff' : color;
  currentVisualizerColor = color;
}
