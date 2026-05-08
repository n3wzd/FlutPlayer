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
  final String backgroundGroupDBTableName = '_background_group';
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
      'CREATE TABLE IF NOT EXISTS $backgroundGroupDBTableName (path TEXT PRIMARY KEY, active BOOL NOT NULL DEFAULT FALSE, rotate BOOL NOT NULL DEFAULT FALSE, scale INTEGER NOT NULL DEFAULT 0, color INTEGER NOT NULL DEFAULT 0, value INTEGER NOT NULL DEFAULT 75);',
    );
    await DatabaseInterface.instance.execute(
      'CREATE TABLE IF NOT EXISTS $mixDBTableName (path TEXT PRIMARY KEY);',
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
      List<Map> tracks = [];
      final titles = _readTagTitles(tableName);
      for (String title in titles) {
        AudioTrack? track = await importTrack(title);
        if (track != null) {
          tracks.add({
            'title': track.title,
            'path': track.path,
            'modified_time': track.modifiedDateTime,
            'color': track.color,
          });
        }
      }
      return tracks;
    }
    return [];
  }

  Future<List<Map>> selectAllDBTable() async {
    return _selectTagFiles();
  }

  Future<bool> checkDBTableExist(String tableName) async {
    return File(_tagCsvPath(tableName)).existsSync();
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

  Future<void> insertBackgroundGroup(BackgroundData data, bool active) async {
    await DatabaseInterface.instance.rawInsert(
      'INSERT OR IGNORE INTO $backgroundGroupDBTableName(path, active, rotate, scale, color, value) VALUES(?, ?, ?, ?, ?, ?);',
      [
        data.path,
        active ? 1 : 0,
        data.rotate ? 1 : 0,
        data.scale ? 1 : 0,
        data.color ? 1 : 0,
        data.value,
      ],
    );
  }

  Future<List<Map>> selectAllBackgroundGroup() async {
    var list = await DatabaseInterface.instance.rawQuery(
      'SELECT * FROM $backgroundGroupDBTableName ORDER BY path ASC;',
    );
    return List<Map>.from(list);
  }

  Future<BackgroundData> selectBackgroundGroup(String path) async {
    var data = await DatabaseInterface.instance.rawQuery(
      'SELECT * FROM $backgroundGroupDBTableName WHERE path=?;',
      [path],
    );
    return BackgroundData(
      path: path,
      rotate: data[0]['rotate'] == 1 ? true : false,
      scale: data[0]['scale'] == 1 ? true : false,
      color: data[0]['color'] == 1 ? true : false,
      value: data[0]['value'],
    );
  }

  Future<void> updateBackgroundGroup(String path, BackgroundData data) async {
    await DatabaseInterface.instance.execute(
      'UPDATE $backgroundGroupDBTableName SET rotate=?, scale=?, color=?, value=? WHERE path=?;',
      [
        data.rotate ? 1 : 0,
        data.scale ? 1 : 0,
        data.color ? 1 : 0,
        data.value,
        path,
      ],
    );
  }

  Future<void> deleteBackgroundGroup(String path) async {
    await DatabaseInterface.instance.execute(
      'DELETE FROM $backgroundGroupDBTableName WHERE path=?;',
      [path],
    );
  }

  Future<void> toggleBackgroundGroupActive(String path, bool value) async {
    await DatabaseInterface.instance.execute(
      'UPDATE $backgroundGroupDBTableName SET active=? WHERE path=?;',
      [value ? 1 : 0, path],
    );
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

  List<Map> _selectTagFiles() {
    if (Preference.tagRootPath.isEmpty ||
        !Directory(Preference.tagRootPath).existsSync()) {
      return [];
    }
    final files = Directory(Preference.tagRootPath)
        .listSync()
        .whereType<File>()
        .where((file) => path.extension(file.path).toLowerCase() == '.csv')
        .map<Map<String, String>>(
          (file) => {'name': path.basenameWithoutExtension(file.path)},
        )
        .toList();
    files.sort((a, b) => a['name']!.compareTo(b['name']!));
    return files;
  }

  Future<void> _dropTagTable() async {
    await DatabaseInterface.instance.execute('DROP TABLE IF EXISTS _table;');
  }

  List<String> _readTagTitles(String tableName) {
    final file = File(_tagCsvPath(tableName));
    if (!file.existsSync()) {
      return [];
    }
    final lines = file.readAsLinesSync(encoding: utf8);
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
