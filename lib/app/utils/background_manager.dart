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
  final Map<String, BackgroundGroup> _backgroundGroupMap = {};
  BackgroundData _currentBackgroundData = BackgroundData(path: '');

  bool get isListNotEmpty => _backgroundList.isNotEmpty;
  BackgroundData get currentBackgroundData => _currentBackgroundData;

  Future<void> init() async {
    List<Map> dirList = await DatabaseManager.instance.selectAllBackgroundGroup();
    for(int i = 0; i < dirList.length; i++) {
      String path = dirList[i]['path'];
      BackgroundData data = BackgroundData(
        path: path,
        rotate: dirList[i]['rotate'] == 1 ? true : false,
        scale: dirList[i]['scale'] == 1 ? true : false,
        color: dirList[i]['color'] == 1 ? true : false,
        value: dirList[i]['value'],
      );
      addBackgroundGroup(path, data);
    }
  }

  void addBackgroundGroup(String path, BackgroundData data) {
    var group = BackgroundGroup(dirPath: path, dirBackgroundData: data);
    group.init();
    _backgroundList.addAll(group.makeGroupList());
    _backgroundGroupMap[path] = group;
  }

  void updateBackgroundGroup(String path, BackgroundData data) {
    _backgroundGroupMap[path]?.dirBackgroundData = data;
    updateBackgroundList();
  }

  void deleteBackgroundGroup(String path) {
    _backgroundGroupMap.remove(path);
  }

  void updateBackgroundList() {
    _backgroundList = [];
    for (var entry in _backgroundGroupMap.entries) {
      _backgroundList.addAll(entry.value.makeGroupList());
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
  List<String> filePathList = [];

  void init() {
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
    }
  }

  List<BackgroundData> makeGroupList() {
    List<BackgroundData> list = [];
    for(String path in filePathList) {
      list.add(BackgroundData(
          path: path,
          rotate: dirBackgroundData.rotate,
          scale: dirBackgroundData.scale,
          color: dirBackgroundData.color,
          value: dirBackgroundData.value,
        ));
    }
    return list;
  }
}
