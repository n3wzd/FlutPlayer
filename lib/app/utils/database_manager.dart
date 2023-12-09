import 'package:sqflite/sqflite.dart';
import 'package:file_picker/file_picker.dart';
import '../models/audio_track.dart';
import '../models/visualizer_color.dart';
import './playlist.dart';
import './stream_controller.dart';
import './permission_handler.dart';
import 'dart:io';

class DatabaseManager {
  DatabaseManager._();
  static final DatabaseManager _instance = DatabaseManager._();
  static DatabaseManager get instance => _instance;

  final String databaseFileName = 'audio_track.db';
  final String mainDBTableName = '_main';
  final String tableMasterDBTableName = '_table';
  final String colorDBTableName = '_color';
  late final Database database;
  late final String databasesPath;

  String _tagDBtableName(String name) => '_tag_${name.replaceAll(' ', '_')}';

  void init() async {
    final path = await getDatabasesPath();
    databasesPath = '$path/$databaseFileName';
    if (await databaseExists(databasesPath)) {
      database = await openDatabase(databasesPath);
    } else {
      database = await openDatabase(databasesPath);
      await database.execute(
          'CREATE TABLE IF NOT EXISTS $mainDBTableName (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, title TINYTEXT UNIQUE, path TINYTEXT, color INTEGER NOT NULL DEFAULT 0);');
      await database.execute(
          'CREATE TABLE IF NOT EXISTS $tableMasterDBTableName (name TEXT NOT NULL UNIQUE, favorite BOOL NOT NULL DEFAULT FALSE);');
      await database.execute(
          'CREATE TABLE IF NOT EXISTS $colorDBTableName (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, name TINYTEXT NOT NULL UNIQUE, value INTEGER NOT NULL);');
      await database.transaction((txn) async {
        await txn.rawInsert(
            'INSERT OR IGNORE INTO $colorDBTableName(name, value, id) VALUES("null", 0, 0);');
        for (VisualizerColor color in defaultVisualizerColors) {
          _insertColorToDBColorTable(txn, color);
        }
      });
    }
  }

  void dispose() {
    database.close();
  }

  void exportList(String tableName, bool autoAddPlaylist) async {
    if (!(await checkDBTableExist(tableName))) {
      await database.transaction((txn) async {
        await _createDBTable(txn, tableName);
        if (autoAddPlaylist) {
          await _insertListToDBTagTable(txn, tableName);
        }
      });
    }
  }

  void deleteList(String tableName) async {
    if (await checkDBTableExist(tableName)) {
      await database.transaction((txn) async {
        await _deleteDBTable(txn, tableName);
      });
    }
  }

  void updateList(String tableName) async {
    if (await checkDBTableExist(tableName)) {
      await database.transaction((txn) async {
        await _deleteDBTable(txn, tableName);
        await _createDBTable(txn, tableName);
        await _insertListToDBTagTable(txn, tableName);
      });
    }
  }

  Future<List<Map>> importList(String tableName) async {
    if (await checkDBTableExist(tableName)) {
      return await database.rawQuery(
          'SELECT title, path, value AS color FROM $mainDBTableName, $colorDBTableName, ${_tagDBtableName(tableName)} WHERE $mainDBTableName.id = ${_tagDBtableName(tableName)}.id AND $colorDBTableName.id = $mainDBTableName.color ORDER BY sortIdx ASC;');
    }
    return [];
  }

  Future<List<Map>> selectAllDBTable({bool favoriteFilter = false}) async {
    String extraQuery = favoriteFilter ? 'WHERE favorite=TRUE' : '';
    var list = await database.rawQuery(
        'SELECT * FROM $tableMasterDBTableName $extraQuery ORDER BY name ASC;');
    return List<Map>.from(list);
  }

  Future<List<Map>> selectAllDBColor() async {
    var list = await database.rawQuery(
        'SELECT * FROM $colorDBTableName WHERE id != 0 ORDER BY id ASC;');
    return List<Map>.from(list);
  }

  void toggleDBTableFavorite(String tableName) async {
    if (await checkDBTableExist(tableName)) {
      bool? fav = await selectDBTableFavorite(tableName);
      if (fav != null) {
        await database.execute(
            'UPDATE $tableMasterDBTableName SET favorite=${!fav} WHERE name="$tableName";');
      }
    }
  }

  Future<bool?> selectDBTableFavorite(String tableName) async {
    if (await checkDBTableExist(tableName)) {
      List<Map> data = await database.rawQuery(
          'SELECT favorite FROM $tableMasterDBTableName WHERE name="$tableName";');
      return data[0]['favorite'] == 0 ? false : true;
    }
    return null;
  }

  Future<bool> checkDBTableExist(String tableName) async {
    List<Map> data = await database.rawQuery(
        'SELECT name FROM $tableMasterDBTableName WHERE name="$tableName";');
    return data.isNotEmpty;
  }

  void addItemInDBTable(
      {required String tableName, required String trackTitle}) async {
    AudioTrack? track = PlayList.instance.playMap[trackTitle];
    if (track != null) {
      if (await checkDBTableExist(tableName)) {
        await database.transaction((txn) async {
          await _insertTrackToDBMainTable(txn, track);
          await _insertTrackToDBTagTable(txn, tableName, track.title);
        });
      }
    }
  }

  void createDBTable(String tableName) async {
    if (!(await checkDBTableExist(tableName))) {
      await database.transaction((txn) async {
        await _createDBTable(txn, tableName);
      });
    }
  }

  void updateDBTrackColor(AudioTrack track, VisualizerColor color) async {
    await database.transaction((txn) async {
      await _insertTrackToDBMainTable(txn, track);
      await _insertColorToDBColorTable(txn, color);
    });
    List<Map> trackData = await database.rawQuery(
        'SELECT id FROM $mainDBTableName WHERE title="${track.title}";');
    List<Map> colorData = await database.rawQuery(
        'SELECT id FROM $colorDBTableName WHERE name="${color.name}";');
    if (trackData.isNotEmpty && colorData.isNotEmpty) {
      await database.execute(
          'UPDATE $mainDBTableName SET color=${colorData[0]["id"]} WHERE id=${trackData[0]["id"]};');
    }
    AudioStreamController.visualizerColor.add(null);
  }

  Future<void> _insertListToDBTagTable(
      Transaction txn, String tableName) async {
    for (String trackTitle in PlayList.instance.playList) {
      AudioTrack? track = PlayList.instance.playMap[trackTitle];
      if (track != null) {
        await _insertTrackToDBMainTable(txn, track);
        await _insertTrackToDBTagTable(txn, tableName, track.title);
      }
    }
  }

  Future<void> _insertTrackToDBMainTable(
      Transaction? txn, AudioTrack track) async {
    String sql =
        'INSERT OR IGNORE INTO $mainDBTableName(title, path) VALUES("${track.title}", "${track.path}")';
    if (txn != null) {
      await txn.rawInsert(sql);
    } else {
      await database.rawQuery(sql);
    }
  }

  Future<void> _insertColorToDBColorTable(
      Transaction? txn, VisualizerColor color) async {
    String sql =
        'INSERT OR IGNORE INTO $colorDBTableName(name, value) VALUES("${color.name}", ${color.value})';
    if (txn != null) {
      await txn.rawInsert(sql);
    } else {
      await database.rawQuery(sql);
    }
  }

  Future<void> _insertTrackToDBTagTable(
      Transaction txn, String tableName, String title) async {
    List<Map> data = await txn
        .rawQuery('SELECT id FROM $mainDBTableName WHERE title = "$title";');
    if (data.isNotEmpty) {
      int id = data[0]['id'];
      await txn.rawInsert(
          'INSERT OR IGNORE INTO ${_tagDBtableName(tableName)}(id) VALUES($id);');
    }
  }

  Future<void> _createDBTable(Transaction txn, String tableName) async {
    txn.rawInsert(
        'CREATE TABLE ${_tagDBtableName(tableName)} (sortIdx INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, id INTEGER NOT NULL UNIQUE);');
    txn.rawInsert(
        'INSERT INTO $tableMasterDBTableName(name) VALUES("$tableName");');
  }

  Future<void> _deleteDBTable(Transaction txn, String tableName) async {
    txn.execute('DROP TABLE ${_tagDBtableName(tableName)};');
    txn.execute('DELETE FROM $tableMasterDBTableName WHERE name="$tableName";');
  }

  Future<void> exportDBFile() async {
    if (!PermissionHandler.instance.isPermissionAccepted) {
      return;
    }
    String? selectedDirectoryPath =
        await FilePicker.platform.getDirectoryPath();
    if (selectedDirectoryPath != null) {
      File file = File(databasesPath);
      file.copy('$selectedDirectoryPath/$databaseFileName');
    }
  }

  Future<void> importDBFile() async {
    if (!PermissionHandler.instance.isPermissionAccepted) {
      return;
    }
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
    );
    if (result != null) {
      String name = result.files[0].name;
      if (name == databaseFileName) {
        String? path = result.files[0].path;
        if (path != null) {
          File file = File(path);
          file.copy(databasesPath);
        }
      }
    }
  }

  Future<void> tagDBToCsv() async {
    String? selectedDirectoryPath =
        await FilePicker.platform.getDirectoryPath();
    if (selectedDirectoryPath != null) {
      List<Map> tables = await selectAllDBTable();
      for (Map table in tables) {
        String tableName = table['name'];
        List<Map>? datas = await importList(tableName);
        File file = File('$selectedDirectoryPath/$tableName.csv');
        String buffer = '';
        buffer += '"title"\n';
        for (Map data in datas) {
          buffer += '"${data["title"]}"\n';
        }
        file.writeAsStringSync(buffer);
      }
    }
  }

  Future<void> tagCsvToDB() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (result != null) {
      String? path = result.files[0].path;
      String tableName = result.files[0].name;
      tableName = tableName.substring(0, tableName.length - 4);
      if (path != null) {
        File file = File(path);
        List<String> datas = file.readAsLinesSync();
        if (!(await checkDBTableExist(tableName))) {
          await database.transaction((txn) async {
            await _createDBTable(txn, tableName);
            int cnt = 0;
            for (String data in datas) {
              if (cnt++ == 0) {
                continue;
              }
              await _insertTrackToDBTagTable(
                  txn, tableName, data.substring(1, data.length - 1));
            }
          });
        }
      }
    }
  }
}
