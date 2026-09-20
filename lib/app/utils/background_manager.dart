import 'dart:io';
import './background_store.dart';
import './emergency_food_background_source.dart';
import './file_recency_resolver.dart';
import './preference.dart';
import './recency_weighted_selector.dart';
import '../models/data.dart';

const List<String> backgroundAllowedExtensions = ['png', 'jpg', 'gif', 'mp4'];

class BackgroundManager {
  BackgroundManager._();
  static final BackgroundManager _instance = BackgroundManager._();
  static BackgroundManager get instance => _instance;

  BackgroundStoreData _settings = BackgroundStoreData();
  final RecencyWeightedSelector<BackgroundData> _selector =
      RecencyWeightedSelector();
  BackgroundData? _currentBackgroundData;
  bool _initialized = false;

  List<BackgroundGroupData> get _groups => _settings.groups;
  List<BackgroundGroupData> get groups => _settings.groups;
  String get emergencyFoodDataRoot => _settings.emergencyFoodDataRoot;
  List<String> get emergencyFoodBackgroundRoots =>
      List.unmodifiable(_settings.emergencyFoodBackgroundRoots);

  bool get isListNotEmpty => _selector.isNotEmpty;
  bool isManagedGroup(String label) =>
      _groups.any((group) => group.label == label && group.managed);
  BackgroundData get currentBackgroundData =>
      _currentBackgroundData ?? BackgroundData(path: '');

  bool? get currentNcsLogoOverride => currentBackgroundData.ncsLogo;
  bool? get currentVisualizerOverride => currentBackgroundData.visualizer;

  Future<void> init() async {
    if (_initialized) {
      return;
    }
    await reload();
    _initialized = true;
  }

  Future<void> reload() async {
    _settings = await BackgroundStore.instance.load();
    await EmergencyFoodBackgroundSource.instance.sync(
      groups: _groups,
      dataRoot: _settings.emergencyFoodDataRoot,
      backgroundRoots: _settings.emergencyFoodBackgroundRoots,
    );
    updateBackgroundList();
  }

  Future<void> updateEmergencyFoodPaths({
    required String dataRoot,
    required List<String> backgroundRoots,
  }) async {
    _settings.emergencyFoodDataRoot = dataRoot;
    _settings.emergencyFoodBackgroundRoots = List.from(backgroundRoots);
    try {
      await EmergencyFoodBackgroundSource.instance.sync(
        groups: _groups,
        dataRoot: dataRoot,
        backgroundRoots: backgroundRoots,
      );
      await _save();
      updateBackgroundList();
    } catch (_) {
      _settings = await BackgroundStore.instance.load();
      await EmergencyFoodBackgroundSource.instance.sync(
        groups: _groups,
        dataRoot: _settings.emergencyFoodDataRoot,
        backgroundRoots: _settings.emergencyFoodBackgroundRoots,
      );
      updateBackgroundList();
      rethrow;
    }
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
    await BackgroundStore.instance.save(_settings);
  }

  void updateBackgroundList() {
    final candidates = <RecencyWeightedCandidate<BackgroundData>>[];
    final seen = <String>{};
    for (final group in _groups) {
      if (!group.active) {
        continue;
      }
      for (final folder in group.folders) {
        for (final file in _scanFolder(folder)) {
          if (seen.add(file.path)) {
            final background = BackgroundData(
              path: file.path,
              brightness: group.brightness,
              ncsLogo: group.ncsLogo,
              visualizer: group.visualizer,
            );
            candidates.add(
              RecencyWeightedCandidate(
                key: file.path,
                value: background,
                recency: file.recency,
              ),
            );
          }
        }
      }
    }
    _selector.replace(candidates);
    _currentBackgroundData = null;
    randomizeCurrentBackgroundList();
  }

  void randomizeCurrentBackgroundList() {
    _currentBackgroundData = _selector.next(
      recencyWeight: Preference.latestBackgroundWeight,
    );
  }

  List<_BackgroundFile> _scanFolder(String dirPath) {
    final result = <_BackgroundFile>[];
    if (dirPath.isEmpty) {
      return result;
    }
    final directory = Directory(dirPath);
    if (!directory.existsSync()) {
      return result;
    }
    for (final entity in directory.listSync(recursive: true)) {
      final path = entity.path;
      if (!FileSystemEntity.isDirectorySync(path) &&
          backgroundAllowedExtensions.contains(path.split('.').last)) {
        final file = File(path);
        result.add(
          _BackgroundFile(
            path: path,
            recency: FileRecencyResolver.resolve(file),
          ),
        );
      }
    }
    return result;
  }
}

class _BackgroundFile {
  const _BackgroundFile({required this.path, required this.recency});

  final String path;
  final DateTime recency;
}
