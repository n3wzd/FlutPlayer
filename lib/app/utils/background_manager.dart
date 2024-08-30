import 'dart:math';
import 'dart:io';
import './stream_controller.dart';
import './database_manager.dart';
import '../models/data.dart';

const List<String> backgroundAllowedExtensions = ['png', 'jpg', 'gif', 'mp4'];

class BackgroundManager {
  BackgroundManager._();
  static final BackgroundManager _instance = BackgroundManager._();
  static BackgroundManager get instance => _instance;

  List<BackgroundData> _backgroundList = [];
  List<BackgroundGroup> _backgroundGroupList = [];
  BackgroundData _currentBackgroundData = BackgroundData(path: '');

  bool get isListNotEmpty => _backgroundList.isNotEmpty;
  BackgroundData get currentBackgroundData => _currentBackgroundData;

  void init() {
    updateBackgroundList();
  }

  void updateBackgroundList() async {
    _backgroundList = [];
    List<Map> dirList = await DatabaseManager.instance.selectAllBackgroundGroup();
    for(int i = 0; i < dirList.length; i++) {
      String directoryPath = dirList[i]['path'];

      /*dirBackgroundData = BackgroundData(
        path: directoryPath,
        rotate: dirList[i]['rotate'] == 1 ? true : false,
        scale: dirList[i]['scale'] == 1 ? true : false,
        color: dirList[i]['color'] == 1 ? true : false,
        value: dirList[i]['value'],
      );*/
    }
    setCurrentBackgroundList();
  }

  void setCurrentBackgroundList() {
    if (_backgroundList.isNotEmpty) {
      _currentBackgroundData = _backgroundList[Random().nextInt(_backgroundList.length)];
      AudioStreamController.backgroundFile.add(null);
    }
  }
}

class BackgroundGroup {
  BackgroundGroup({required this.dirPath, required this.dirBackgroundData});

  final String dirPath;
  BackgroundData dirBackgroundData;
  bool isLoaded = false;
  List<String> filePathList = [];

  void load() {
    if(isLoaded) {
      return;
    }
    if (dirPath != '') {
      Directory selectedDirectory = Directory(dirPath);
      if (selectedDirectory.existsSync()) {
        List<FileSystemEntity> selectedDirectoryFile =
        selectedDirectory.listSync(recursive: true);
        for (FileSystemEntity file in selectedDirectoryFile) {
          String path = file.path;
          if (!FileSystemEntity.isDirectorySync(path)) {
            if (backgroundAllowedExtensions.contains(path
                .split('.')
                .last)) {
              filePathList.add(path);
            }
          }
        }
      }
      isLoaded = true;
    }
  }
}
