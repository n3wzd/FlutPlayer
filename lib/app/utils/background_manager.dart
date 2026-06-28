import 'dart:io';
import './background_store.dart';
import '../models/data.dart';

const List<String> backgroundAllowedExtensions = ['png', 'jpg', 'gif', 'mp4'];

class BackgroundManager {
  BackgroundManager._();
  static final BackgroundManager _instance = BackgroundManager._();
  static BackgroundManager get instance => _instance;

  List<BackgroundData> _backgroundList = [];
  List<BackgroundGroupData> _groups = [];
  int currentBackgroundListIndex = 0;
  bool _initialized = false;

  List<BackgroundGroupData> get groups => _groups;

  bool get isListNotEmpty => _backgroundList.isNotEmpty;
  int get nextBackgroundListIndex => isListNotEmpty
      ? (currentBackgroundListIndex + 1) % _backgroundList.length
      : 0;
  BackgroundData get currentBackgroundData => isListNotEmpty
      ? _backgroundList[currentBackgroundListIndex]
      : BackgroundData(path: "");
  BackgroundData get nextBackgroundData => isListNotEmpty
      ? _backgroundList[nextBackgroundListIndex]
      : BackgroundData(path: "");

  /// Override for the currently shown background, or null to inherit the global
  /// setting (also null when no background is active).
  bool? get currentNcsLogoOverride => currentBackgroundData.ncsLogo;
  bool? get currentVisualizerOverride => currentBackgroundData.visualizer;

  Future<void> init() async {
    if (_initialized) {
      return;
    }
    _groups = await BackgroundStore.instance.load();
    updateBackgroundList();
    _initialized = true;
  }

  bool hasLabel(String label) => _groups.any((group) => group.label == label);

  Future<void> addGroup(BackgroundGroupData group) async {
    _groups.add(group);
    await _save();
  }

  Future<void> updateGroup(
    String originalLabel,
    BackgroundGroupData group,
  ) async {
    final index = _groups.indexWhere((g) => g.label == originalLabel);
    if (index == -1) {
      return;
    }
    _groups[index] = group;
    await _save();
  }

  Future<void> setGroupActive(String label, bool active) async {
    final group = _groups.firstWhere(
      (g) => g.label == label,
      orElse: () => BackgroundGroupData(label: ''),
    );
    if (group.label.isEmpty) {
      return;
    }
    group.active = active;
    await _save();
  }

  Future<void> deleteGroup(String label) async {
    _groups.removeWhere((group) => group.label == label);
    await _save();
  }

  Future<void> _save() async {
    await BackgroundStore.instance.save(_groups);
  }

  void updateBackgroundList() {
    _backgroundList = [];
    final seen = <String>{};
    for (final group in _groups) {
      if (!group.active) {
        continue;
      }
      for (final folder in group.folders) {
        for (final filePath in _scanFolder(folder)) {
          // Runtime dedupe: the same file from overlapping folders/groups is
          // only shown once. First occurrence wins (keeps its group brightness).
          if (seen.add(filePath)) {
            _backgroundList.add(
              BackgroundData(
                path: filePath,
                brightness: group.brightness,
                ncsLogo: group.ncsLogo,
                visualizer: group.visualizer,
              ),
            );
          }
        }
      }
    }
    currentBackgroundListIndex = 0;
    _backgroundList.shuffle();
    randomizeCurrentBackgroundList();
  }

  void randomizeCurrentBackgroundList() {
    if (isListNotEmpty) {
      currentBackgroundListIndex = nextBackgroundListIndex;
    }
  }

  List<String> _scanFolder(String dirPath) {
    final result = <String>[];
    if (dirPath.isEmpty) {
      return result;
    }
    final directory = Directory(dirPath);
    if (!directory.existsSync()) {
      return result;
    }
    for (final file in directory.listSync(recursive: true)) {
      final path = file.path;
      if (!FileSystemEntity.isDirectorySync(path) &&
          backgroundAllowedExtensions.contains(path.split('.').last)) {
        result.add(path);
      }
    }
    return result;
  }
}
