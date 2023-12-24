import 'dart:async';
import 'dart:math';
import 'dart:io';
import './utils/audio_manager.dart';
import './utils/database_manager.dart';
import './utils/audio_handler.dart';
import './utils/preference.dart';
import './utils/permission_handler.dart';

/*bool get isAndroid => Platform.isAndroid;
bool get isWindows => Platform.isWindows;
bool get isWeb => !isAndroid && !isWindows;*/
bool get isAndroid => true;
bool get isWindows => false;
bool get isWeb => false;

bool isFullScreen = false;

String debugLog = '';
final debugLogStreamController = StreamController<void>.broadcast();

double playListSavedScrollPosition = 0;

void initApp() async {
  await Preference.init();
  if (!isWeb) {
    DatabaseManager.instance.init();
  }
  if (isAndroid) {
    PermissionHandler.instance.init();
  }
  AudioManager.instance.init();
  if (isAndroid) {
    createAudioSerivce();
  }
  setBackgroundPathList();
}

const List<String> backgroundAllowedExtensions = ['png', 'jpg', 'gif', 'mp4'];
List<String> backgroundPathList = [];
int backgroundPathListCurrentIndex = 0;

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
  setbackgroundPathListCurrentIndex();
}

void setbackgroundPathListCurrentIndex() {
  if (backgroundPathList.isNotEmpty) {
    backgroundPathListCurrentIndex =
        Random().nextInt(backgroundPathList.length);
  }
}
