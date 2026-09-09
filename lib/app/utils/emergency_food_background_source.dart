import 'dart:convert';
import 'dart:io';

import '../models/data.dart';

class EmergencyFoodBackgroundSource {
  EmergencyFoodBackgroundSource._();

  static final EmergencyFoodBackgroundSource instance =
      EmergencyFoodBackgroundSource._();

  static const Set<String> _categories = {'Uncaged', 'Instinct'};
  static const int _structuredBackgroundStartYear = 2021;
  static final RegExp _managedLabel = RegExp(
    r'^비상식량-(Uncaged|Instinct) (\d{4})$',
  );

  Future<void> sync({
    required List<BackgroundGroupData> groups,
    required String dataRoot,
    required List<String> backgroundRoots,
  }) async {
    if (!Platform.isWindows || dataRoot.isEmpty) {
      return;
    }
    if (backgroundRoots.isEmpty) {
      throw StateError(
        'Emergency-food data root is configured without background roots: $dataRoot',
      );
    }

    final roots = <String>{...backgroundRoots};
    final years = await _loadYears(dataRoot);
    for (final year in years) {
      if (int.parse(year) < _structuredBackgroundStartYear) {
        continue;
      }
      final assignments = await _loadAssignments(dataRoot, year);
      if (assignments == null) {
        continue;
      }
      for (final category in _categories) {
        final folders = <String>[];
        for (final game in assignments[category]!) {
          folders.add(
            _resolveFolder(
              roots: roots,
              year: year,
              game: game,
              category: category,
            ),
          );
        }
        _replaceGroupFolders(groups, category, year, folders);
      }
    }
  }

  Future<List<String>> _loadYears(String dataRoot) async {
    final path = '$dataRoot\\emergency-food-meta.json';
    final decoded = await _decode(File(path));
    if (decoded is! Map || decoded['years'] is! List) {
      throw FormatException('Invalid emergency-food metadata: $path');
    }
    final years = <String>[];
    for (final value in decoded['years'] as List) {
      if (value is! num) {
        throw FormatException('Invalid emergency-food year in $path: $value');
      }
      years.add(value.toInt().toString());
    }
    return years;
  }

  Future<Map<String, List<String>>?> _loadAssignments(
    String dataRoot,
    String year,
  ) async {
    final path = '$dataRoot\\data\\$year.json';
    final decoded = await _decode(File(path));
    if (decoded is! List) {
      throw FormatException('Invalid emergency-food data: $path');
    }

    final assignments = {
      for (final category in _categories) category: <String>[],
    };
    var hasBackgroundField = false;
    for (final entry in decoded) {
      if (entry is! Map) {
        throw FormatException('Invalid emergency-food record in $path');
      }
      if (!entry.containsKey('background')) {
        continue;
      }
      hasBackgroundField = true;
      final game = entry['game'];
      final background = entry['background'];
      if (game is! String || game.isEmpty || background is! List) {
        throw FormatException('Invalid background record in $path: $game');
      }
      for (final category in background) {
        if (category is! String || !_categories.contains(category)) {
          throw FormatException(
            'Invalid background category in $path for $game: $category',
          );
        }
        assignments[category]!.add(game);
      }
    }
    return hasBackgroundField ? assignments : null;
  }

  Future<Object?> _decode(File file) async {
    if (!await file.exists()) {
      throw FileSystemException(
        'Emergency-food data file not found.',
        file.path,
      );
    }
    try {
      return jsonDecode(await file.readAsString());
    } on FormatException catch (error) {
      throw FormatException('Invalid JSON in ${file.path}: ${error.message}');
    }
  }

  String _resolveFolder({
    required Set<String> roots,
    required String year,
    required String game,
    required String category,
  }) {
    final attempted = <String>[];
    final candidates = <String>{};
    for (final root in roots) {
      final yearDirectory = Directory('$root\\$year');
      final exact = '${yearDirectory.path}\\$game';
      attempted.add(exact);
      if (Directory(exact).existsSync()) {
        candidates.add(exact);
        continue;
      }
      if (!yearDirectory.existsSync()) {
        continue;
      }
      for (final entity in yearDirectory.listSync()) {
        if (entity is Directory && _matchesGameFolder(entity.path, game)) {
          candidates.add(entity.path);
        }
      }
    }
    if (candidates.length != 1) {
      throw FileSystemException(
        'Expected one background folder for $category/$year/$game, found ${candidates.length}.',
        attempted.join(', '),
      );
    }
    return candidates.single;
  }

  bool _matchesGameFolder(String folder, String game) {
    final folderName = _basename(folder);
    if (_normalizeName(folderName) == _normalizeName(game)) {
      return true;
    }

    final folderRange = RegExp(r'^(.*) (\d+)-(\d+)$').firstMatch(folderName);
    final gameNumber = RegExp(r'^(.*) (\d+)$').firstMatch(game);
    if (folderRange == null || gameNumber == null) {
      return false;
    }
    if (_normalizeName(folderRange.group(1)!) !=
        _normalizeName(gameNumber.group(1)!)) {
      return false;
    }
    final value = int.parse(gameNumber.group(2)!);
    final start = int.parse(folderRange.group(2)!);
    final end = int.parse(folderRange.group(3)!);
    return value >= start && value <= end;
  }

  String _normalizeName(String value) {
    final withoutYear = value.replaceFirst(RegExp(r'\s*\(\d{4}\)$'), '');
    final withoutVersion = withoutYear.replaceFirst(
      RegExp(r'\s+\d+(?:\.\d+)+$'),
      '',
    );
    return withoutVersion.toLowerCase().replaceAll(
      RegExp(r'''[\s_\-().,!]'''),
      '',
    );
  }

  void _replaceGroupFolders(
    List<BackgroundGroupData> groups,
    String category,
    String year,
    List<String> folders,
  ) {
    final label = '비상식량-$category $year';
    final index = groups.indexWhere((group) => group.label == label);
    if (index >= 0) {
      groups[index].folders = folders;
      groups[index].managed = true;
      return;
    }

    final template = _latestCategoryGroup(groups, category);
    groups.add(
      BackgroundGroupData(
        label: label,
        active: template?.active ?? true,
        brightness: template?.brightness ?? backgroundDefaultBrightness,
        ncsLogo: template?.ncsLogo,
        visualizer: template?.visualizer,
        managed: true,
        folders: folders,
      ),
    );
  }

  BackgroundGroupData? _latestCategoryGroup(
    List<BackgroundGroupData> groups,
    String category,
  ) {
    BackgroundGroupData? latest;
    var latestYear = -1;
    for (final group in groups) {
      final match = _managedLabel.firstMatch(group.label);
      if (match == null || match.group(1) != category) {
        continue;
      }
      final year = int.parse(match.group(2)!);
      if (year > latestYear) {
        latest = group;
        latestYear = year;
      }
    }
    return latest;
  }

  String _basename(String path) => path.split(Platform.pathSeparator).last;
}
