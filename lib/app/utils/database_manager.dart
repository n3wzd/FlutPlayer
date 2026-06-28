import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'dart:convert';
import 'dart:io';
import './database_interface.dart';
import './preference.dart';
import '../models/data.dart';
import '../models/api.dart';

class DatabaseManager {
  DatabaseManager._();
  static final DatabaseManager _instance = DatabaseManager._();
  static DatabaseManager get instance => _instance;

  final String databaseFileName = 'audio_track.db';
  final String mainDBTableName = '_main';
  final String mixDBTableName = '_mix';
  String databasesPath = '';
  bool _initialized = false;
  final List<String> _audioExtensions = ['mp3', 'wav', 'ogg'];

  Future<void> init() async {
    if (_initialized) {
      return;
    }
    DatabaseInterface.instance.init();
    final path = await DatabaseInterface.instance.getDatabasesPath();
    databasesPath = '$path/$databaseFileName';
    await DatabaseInterface.instance.openDatabaseFile(databasesPath);

    await DatabaseInterface.instance.execute(
      'CREATE TABLE IF NOT EXISTS $mainDBTableName (title TEXT PRIMARY KEY, path TEXT NOT NULL, modified_time TEXT, color TEXT);',
    );
    await DatabaseInterface.instance.execute(
      'CREATE TABLE IF NOT EXISTS $mixDBTableName (path TEXT PRIMARY KEY);',
    );
    await DatabaseInterface.instance.execute(
      'DROP TABLE IF EXISTS _background_group;',
    );
    await _dropTagTable();
    _initialized = true;
  }

  void dispose() {
    DatabaseInterface.instance.dispose();
    _initialized = false;
  }

  Future<List<Map>> importList(String tableName) async {
    if (await checkDBTableExist(tableName)) {
      final titles = await _readTagTitles(tableName);
      if (titles.isEmpty) {
        return [];
      }

      final placeholders = List.filled(titles.length, '?').join(',');
      final rows = await DatabaseInterface.instance.rawQuery(
        'SELECT title, path, modified_time, color FROM $mainDBTableName WHERE title IN ($placeholders);',
        titles,
      );
      final rowsByTitle = {for (final row in rows) row['title'] as String: row};

      return [
        for (final title in titles)
          if (rowsByTitle[title] case final row?)
            {
              'title': row['title'],
              'path': _fullResourcePath(row['path']),
              'modified_time': row['modified_time'],
              'color': row['color'],
            },
      ];
    }
    return [];
  }

  Future<List<Map>> selectAllDBTable() async {
    return _selectTagFiles();
  }

  Future<bool> checkDBTableExist(String tableName) async {
    return File(_tagCsvPath(tableName)).exists();
  }

  Future<AudioTrack?> importTrack(String trackName) async {
    List<Map> datas = await DatabaseInterface.instance.rawQuery(
      'SELECT title, path, modified_time, color FROM $mainDBTableName WHERE title=?;',
      [trackName],
    );
    if (datas.isNotEmpty) {
      return AudioTrack(
        title: datas[0]['title'],
        path: _fullResourcePath(datas[0]['path']),
        modifiedDateTime: datas[0]['modified_time'],
        color: datas[0]['color'],
      );
    }
    return null;
  }

  Future<void> insertMix(String path) async {
    await DatabaseInterface.instance.rawInsert(
      'INSERT OR IGNORE INTO $mixDBTableName(path) VALUES(?);',
      [path],
    );
  }

  Future<List<Map>> selectAllMix() async {
    var list = await DatabaseInterface.instance.rawQuery(
      'SELECT * FROM $mixDBTableName ORDER BY path ASC;',
    );
    return List<Map>.from(list);
  }

  Future<void> deleteMix(String path) async {
    await DatabaseInterface.instance.execute(
      'DELETE FROM $mixDBTableName WHERE path=?;',
      [path],
    );
  }

  Future<APIResult> selectTagRootPath() async {
    bool success = true;
    String msg = '';
    try {
      String? selectedDirectoryPath = await FilePicker.getDirectoryPath();
      if (selectedDirectoryPath != null) {
        Preference.tagRootPath = selectedDirectoryPath;
        await Preference.save(PreferenceKey.tagRootPath);
      } else {
        success = false;
        msg = 'No Directory Chosen.';
      }
    } catch (e) {
      success = false;
      msg = e.toString();
    }
    return APIResult(success: success, msg: msg);
  }

  Future<APIResult> selectResourceRootPath() async {
    bool success = true;
    String msg = '';
    try {
      String? selectedDirectoryPath = await FilePicker.getDirectoryPath();
      if (selectedDirectoryPath != null) {
        Preference.resourceRootPath = selectedDirectoryPath;
        await Preference.save(PreferenceKey.resourceRootPath);
      } else {
        success = false;
        msg = 'No Directory Chosen.';
      }
    } catch (e) {
      success = false;
      msg = e.toString();
    }
    return APIResult(success: success, msg: msg);
  }

  Future<APIResult> syncResourceDatabase() async {
    bool success = true;
    String msg = '';
    try {
      if (Preference.resourceRootPath.isEmpty ||
          !Directory(Preference.resourceRootPath).existsSync()) {
        success = false;
        msg = 'Resource root path is not set.';
        return APIResult(success: success, msg: msg);
      }

      final root = Directory(Preference.resourceRootPath);
      final syncedTitles = <String>{};
      await DatabaseInterface.instance.transaction((txn) async {
        for (FileSystemEntity entity in root.listSync(recursive: true)) {
          if (entity is! File) {
            continue;
          }
          final extension = path.extension(entity.path).replaceFirst('.', '');
          if (!_audioExtensions.contains(extension.toLowerCase())) {
            continue;
          }

          final title = path.basenameWithoutExtension(entity.path);
          final relativePath = path.relative(
            entity.path,
            from: Preference.resourceRootPath,
          );
          final modifiedDateTime = dateTimeToString(entity.statSync().modified);
          syncedTitles.add(title);
          await txn.rawInsert(
            'INSERT OR IGNORE INTO $mainDBTableName(title, path, modified_time, color) VALUES(?, ?, ?, ?);',
            [title, relativePath, modifiedDateTime, ''],
          );
          await txn.execute(
            'UPDATE $mainDBTableName SET path=?, modified_time=? WHERE title=?;',
            [relativePath, modifiedDateTime, title],
          );
        }

        final savedRows = await txn.rawQuery(
          'SELECT title FROM $mainDBTableName;',
        );
        for (Map row in savedRows) {
          final title = row['title'];
          if (!syncedTitles.contains(title)) {
            await txn.execute('DELETE FROM $mainDBTableName WHERE title=?;', [
              title,
            ]);
          }
        }
      });
      msg = '${syncedTitles.length} tracks synchronized.';
    } catch (e) {
      success = false;
      msg = e.toString();
    }
    return APIResult(success: success, msg: msg);
  }

  Future<List<Map>> _selectTagFiles() async {
    if (Preference.tagRootPath.isEmpty ||
        !await Directory(Preference.tagRootPath).exists()) {
      return [];
    }
    final files = <Map<String, String>>[];
    await for (final entity in Directory(Preference.tagRootPath).list()) {
      if (entity is! File) {
        continue;
      }
      if (path.extension(entity.path).toLowerCase() != '.csv') {
        continue;
      }
      files.add({'name': path.basenameWithoutExtension(entity.path)});
    }
    files.sort((a, b) => a['name']!.compareTo(b['name']!));
    return files;
  }

  Future<void> _dropTagTable() async {
    await DatabaseInterface.instance.execute('DROP TABLE IF EXISTS _table;');
  }

  Future<List<String>> _readTagTitles(String tableName) async {
    final file = File(_tagCsvPath(tableName));
    if (!await file.exists()) {
      return [];
    }
    final lines = await file.readAsLines(encoding: utf8);
    final titles = <String>[];
    for (int index = 0; index < lines.length; index++) {
      final columns = _parseCsvLine(lines[index]);
      if (columns.isEmpty) {
        continue;
      }
      if (index == 0 && columns[0].trim().toLowerCase() == 'title') {
        continue;
      }
      final title = columns[0].trim();
      if (title.isNotEmpty) {
        titles.add(title);
      }
    }
    return titles;
  }

  List<String> _parseCsvLine(String line) {
    final columns = <String>[];
    final buffer = StringBuffer();
    bool quoted = false;
    for (int index = 0; index < line.length; index++) {
      final char = line[index];
      if (char == '"') {
        if (quoted && index + 1 < line.length && line[index + 1] == '"') {
          buffer.write('"');
          index++;
        } else {
          quoted = !quoted;
        }
      } else if (char == ',' && !quoted) {
        columns.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }
    columns.add(buffer.toString());
    return columns;
  }

  String _tagCsvPath(String tableName) =>
      path.join(Preference.tagRootPath, '$tableName.csv');

  String _fullResourcePath(String savedPath) {
    if (path.isAbsolute(savedPath) || Preference.resourceRootPath.isEmpty) {
      return savedPath;
    }
    return path.join(Preference.resourceRootPath, savedPath);
  }
}
