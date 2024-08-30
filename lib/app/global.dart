import 'dart:async';
import 'dart:math';
import 'dart:io';
import './utils/audio_manager.dart';
import './utils/playlist.dart';
import './utils/database_manager.dart';
import './utils/audio_handler.dart';
import './utils/preference.dart';
import './utils/permission_handler.dart';
import './models/color.dart';

bool isFullScreen = false;

String debugLog = '';
final debugLogStreamController = StreamController<void>.broadcast();

double playListSavedScrollPosition = 0;

void initApp() async {
  await Preference.init();
  DatabaseManager.instance.init();
  PermissionHandler.instance.init();
  AudioManager.instance.init();
  createAudioSerivce();
  setBackgroundPathList();
}

const List<String> backgroundAllowedExtensions = ['png', 'jpg', 'gif', 'mp4'];
List<String> backgroundPathList = [];
int backgroundPathListCurrentIndex = 0;
String currentVisualizerColor = 'ffffff';

void setBackgroundPathList() {
  backgroundPathList = [];
  String directoryPath = Preference.backgroundDirectoryPath;
  if (directoryPath != '') {
    Directory selectedDirectory = Directory(directoryPath);
    List<FileSystemEntity> selectedDirectoryFile =
        selectedDirectory.listSync(recursive: true);
    for (FileSystemEntity file in selectedDirectoryFile) {
      String path = file.path;
      if (!FileSystemEntity.isDirectorySync(path)) {
        if (backgroundAllowedExtensions.contains(path.split('.').last)) {
          backgroundPathList.add(path);
        }
      }
    }
  }
  setBackgroundPathListCurrentIndex();
}

void setBackgroundPathListCurrentIndex() {
  if (backgroundPathList.isNotEmpty) {
    backgroundPathListCurrentIndex =
        Random().nextInt(backgroundPathList.length);
  }
}

void setVisualizerColor() {
  String color = Preference.randomColorVisualizer ? getRandomColor() : (PlayList.instance.currentAudioColor ?? 'ffffff');
  color = color == 'null' ? 'ffffff' : color;
  currentVisualizerColor = color;
}
