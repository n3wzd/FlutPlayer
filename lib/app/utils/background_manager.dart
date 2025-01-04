import 'dart:io';
import 'dart:async';
import 'dart:math';
import './database_manager.dart';
import '../models/data.dart';
import '../utils/stream_controller.dart';
import '../utils/preference.dart';

const List<String> backgroundAllowedExtensions = ['png', 'jpg', 'gif', 'mp4'];

class BackgroundManager {
  BackgroundManager._();
  static final BackgroundManager _instance = BackgroundManager._();
  static BackgroundManager get instance => _instance;

  List<BackgroundData> _backgroundList = [];
  final Map<String, BackgroundGroup> _backgroundGroupMap = {};
  int currentBackgroundListIndex = 0;

  bool get isListNotEmpty => _backgroundList.isNotEmpty;
  int get nextBackgroundListIndex => (currentBackgroundListIndex + 1) % _backgroundList.length;
  BackgroundData get currentBackgroundData => isListNotEmpty ? 
      _backgroundList[currentBackgroundListIndex] : BackgroundData(path: "");
  BackgroundData get nextBackgroundData => isListNotEmpty ? 
      _backgroundList[nextBackgroundListIndex] : BackgroundData(path: "");

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
      addBackgroundGroup(path, data, dirList[i]['active'] == 1 ? true : false);
    }
    updateBackgroundList();
  }

  void addBackgroundGroup(String path, BackgroundData data, bool active) {
    var group = BackgroundGroup(dirPath: path, dirBackgroundData: data, active: active);
    group.init();
    _backgroundGroupMap[path] = group;
  }

  void updateBackgroundGroup(String path, BackgroundData data) {
    _backgroundGroupMap[path]?.dirBackgroundData = data;
  }

  void updateBackgroundGroupActive(String path, bool active) {
    _backgroundGroupMap[path]?.active = active;
  }

  void deleteBackgroundGroup(String path) {
    _backgroundGroupMap.remove(path);
  }

  void updateBackgroundList() {
    _backgroundList = [];
    for (var entry in _backgroundGroupMap.entries) {
      if(entry.value.active) {
        _backgroundList.addAll(entry.value.makeGroupList());
      }
    }
    currentBackgroundListIndex = 0;
    _backgroundList.shuffle();
    randomizeCurrentBackgroundList();
  }

  void randomizeCurrentBackgroundList() {
    currentBackgroundListIndex = nextBackgroundListIndex;
  }
}

class BackgroundGroup {
  BackgroundGroup({required this.dirPath, required this.dirBackgroundData, required this.active});

  final String dirPath;
  BackgroundData dirBackgroundData;
  List<String> filePathList = [];
  bool active;

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

class BackgroundTransitionTimer {
  BackgroundTransitionTimer._();
  static final BackgroundTransitionTimer _instance = BackgroundTransitionTimer._();
  static BackgroundTransitionTimer get instance => _instance;

  StreamSubscription<void>? _timer;
  
  void init() {
    if(Preference.enableBackgroundTransition) {
      set();
    }
  }

  void set() {
    if(Preference.enableBackgroundTransition) {
      int nextMilliseconds = ((Preference.backgroundNextTriggerMaxTime - Preference.backgroundNextTriggerMinTime) *
          1000 * Random().nextDouble() + Preference.backgroundNextTriggerMinTime * 1000).toInt();
      _timer = Stream<void>.fromFuture(
          Future<void>.delayed(Duration(milliseconds: nextMilliseconds), () {}))
          .listen((x) { 
            BackgroundManager.instance.randomizeCurrentBackgroundList();
            AudioStreamController.backgroundFile.add(null);
            set();
          });
    }
  }

  Future<void> cancel() async {
    if (_timer != null) {
      await _timer!.cancel();
    }
  }

  Future<void> reset() async {
    if (_timer != null) {
      await cancel();
      set();
    }
  }

  void update(bool value) {
    if(value) {
      set();
    } else {
      cancel();
    }
  }
}
