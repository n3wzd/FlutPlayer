import 'dart:convert';
import 'dart:io';
import './database_interface.dart';
import '../models/data.dart';

/// Persists background groups to a single JSON file next to the database.
///
/// Schema:
/// ```json
/// {
///   "groups": [
///     { "label": "dark set", "active": true, "brightness": 40,
///       "folders": ["C:/wallpapers/dark", "C:/wallpapers/night"] }
///   ]
/// }
/// ```
/// Parsing is tolerant: invalid entries/fields are skipped rather than failing
/// the whole load, so a malformed file never crashes the app.
class BackgroundStore {
  BackgroundStore._();
  static final BackgroundStore _instance = BackgroundStore._();
  static BackgroundStore get instance => _instance;

  static const String fileName = 'background_folders.json';

  Future<String> _filePath() async {
    final dir = await DatabaseInterface.instance.getDatabasesPath();
    return '$dir/$fileName';
  }

  Future<List<BackgroundGroupData>> load() async {
    try {
      final file = File(await _filePath());
      if (!await file.exists()) {
        return [];
      }
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map || decoded['groups'] is! List) {
        return [];
      }
      final groups = <BackgroundGroupData>[];
      for (final entry in decoded['groups'] as List) {
        if (entry is! Map) {
          continue;
        }
        final label = entry['label'];
        if (label is! String || label.isEmpty) {
          continue;
        }
        final folders = <String>[];
        final rawFolders = entry['folders'];
        if (rawFolders is List) {
          for (final folder in rawFolders) {
            if (folder is String && folder.isNotEmpty) {
              folders.add(folder);
            }
          }
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
      return groups;
    } catch (_) {
      return [];
    }
  }

  Future<void> save(List<BackgroundGroupData> groups) async {
    final file = File(await _filePath());
    final data = {
      'groups': [
        for (final group in groups)
          {
            'label': group.label,
            'active': group.active,
            'brightness': group.brightness,
            // Omit overrides when null so absence keeps "inherit default".
            if (group.ncsLogo != null) 'ncsLogo': group.ncsLogo,
            if (group.visualizer != null) 'visualizer': group.visualizer,
            'folders': group.folders,
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
