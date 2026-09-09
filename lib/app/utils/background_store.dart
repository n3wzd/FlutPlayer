import 'dart:convert';
import 'dart:io';
import './database_interface.dart';
import '../models/data.dart';

class BackgroundStoreData {
  BackgroundStoreData({
    this.emergencyFoodDataRoot = '',
    List<String>? emergencyFoodBackgroundRoots,
    List<BackgroundGroupData>? groups,
  }) : emergencyFoodBackgroundRoots = emergencyFoodBackgroundRoots ?? [],
       groups = groups ?? [];

  String emergencyFoodDataRoot;
  List<String> emergencyFoodBackgroundRoots;
  List<BackgroundGroupData> groups;
}

class BackgroundStore {
  BackgroundStore._();
  static final BackgroundStore _instance = BackgroundStore._();
  static BackgroundStore get instance => _instance;

  static const String fileName = 'background_folders.json';

  Future<String> _filePath() async {
    final dir = await DatabaseInterface.instance.getDatabasesPath();
    return '$dir/$fileName';
  }

  Future<BackgroundStoreData> load() async {
    final file = File(await _filePath());
    if (!await file.exists()) {
      return BackgroundStoreData();
    }
    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map || decoded['groups'] is! List) {
      throw FormatException('Invalid background settings: ${file.path}');
    }
    final groups = <BackgroundGroupData>[];
    for (final entry in decoded['groups'] as List) {
      if (entry is! Map) {
        throw FormatException('Invalid background group in ${file.path}');
      }
      final label = entry['label'];
      if (label is! String || label.isEmpty) {
        throw FormatException('Invalid background group label in ${file.path}');
      }
      final folders = <String>[];
      final rawFolders = entry['folders'];
      if (rawFolders is! List) {
        throw FormatException('Invalid folders for $label in ${file.path}');
      }
      for (final folder in rawFolders) {
        if (folder is! String || folder.isEmpty) {
          throw FormatException('Invalid folder for $label in ${file.path}');
        }
        folders.add(folder);
      }
      groups.add(
        BackgroundGroupData(
          label: label,
          active: entry['active'] is bool ? entry['active'] as bool : true,
          brightness: _asBrightness(entry['brightness']),
          ncsLogo: entry['ncsLogo'] is bool ? entry['ncsLogo'] as bool : null,
          visualizer: entry['visualizer'] is bool
              ? entry['visualizer'] as bool
              : null,
          folders: folders,
        ),
      );
    }
    final emergencyFood = decoded['emergencyFood'];
    if (emergencyFood == null) {
      return BackgroundStoreData(groups: groups);
    }
    if (emergencyFood is! Map) {
      throw FormatException('Invalid emergency-food settings: ${file.path}');
    }
    final dataRoot = emergencyFood['dataRoot'];
    final rawBackgroundRoots = emergencyFood['backgroundRoots'];
    if (dataRoot is! String || rawBackgroundRoots is! List) {
      throw FormatException('Invalid emergency-food paths: ${file.path}');
    }
    final backgroundRoots = <String>[];
    for (final root in rawBackgroundRoots) {
      if (root is! String || root.isEmpty) {
        throw FormatException('Invalid emergency-food root in ${file.path}');
      }
      backgroundRoots.add(root);
    }
    return BackgroundStoreData(
      emergencyFoodDataRoot: dataRoot,
      emergencyFoodBackgroundRoots: backgroundRoots,
      groups: groups,
    );
  }

  Future<void> save(BackgroundStoreData settings) async {
    final file = File(await _filePath());
    final data = {
      'emergencyFood': {
        'dataRoot': settings.emergencyFoodDataRoot,
        'backgroundRoots': settings.emergencyFoodBackgroundRoots,
      },
      'groups': [
        for (final group in settings.groups)
          {
            'label': group.label,
            'active': group.active,
            'brightness': group.brightness,
            if (group.ncsLogo != null) 'ncsLogo': group.ncsLogo,
            if (group.visualizer != null) 'visualizer': group.visualizer,
            'folders': group.managed ? <String>[] : group.folders,
          },
      ],
    };
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(data));
  }

  int _asBrightness(dynamic value) {
    if (value is int) {
      return value.clamp(0, 100);
    }
    if (value is num) {
      return value.toInt().clamp(0, 100);
    }
    return backgroundDefaultBrightness;
  }
}
