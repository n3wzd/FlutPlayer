import 'package:sqflite/sqflite.dart';
// import 'package:sqflite/sqflite.dart' as sqflite;
// import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:file_picker/file_picker.dart';
import '../models/audio_track.dart';
import '../models/visualizer_color.dart';
import './playlist.dart';
import './stream_controller.dart';
import 'dart:io';
import '../global.dart' as global;

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
    if (global.isWeb) {
      return;
    }
    if (global.isWindows) {
      // sqfliteFfiInit();
    }
    // databaseFactory = databaseFactoryFfi;

    final path = await getDatabasesPath();
    databasesPath = '$path/$databaseFileName';

    if (await databaseExists(databasesPath)) {
      await openDatabaseFile(databasesPath);
    } else {
      await openDatabaseFile(databasesPath);
      await database.execute(
          'CREATE TABLE IF NOT EXISTS $mainDBTableName (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, title TINYTEXT UNIQUE, path TINYTEXT, modified_time TINYTEXT, color INTEGER NOT NULL DEFAULT 0, background_path TINYTEXT);');
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
    if (global.isWeb) {
      return;
    }
    database.close();
  }

  Future<void> openDatabaseFile(String databasesPath) async {
    database = await openDatabase(databasesPath);
    if (global.isAndroid) {
      // database = await sqflite.openDatabase(databasesPath);
    } else {
      // database = await databaseFactoryFfi.openDatabase(databasesPath);
    }
  }

  void exportList(String tableName, bool autoAddPlaylist) async {
    if (global.isWeb) {
      return;
    }
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
    if (global.isWeb) {
      return;
    }
    if (await checkDBTableExist(tableName)) {
      await database.transaction((txn) async {
        await _deleteDBTable(txn, tableName);
      });
    }
  }

  void updateList(String tableName) async {
    if (global.isWeb) {
      return;
    }
    if (await checkDBTableExist(tableName)) {
      await database.transaction((txn) async {
        await _deleteDBTable(txn, tableName);
        await _createDBTable(txn, tableName);
        await _insertListToDBTagTable(txn, tableName);
      });
    }
  }

  Future<List<Map>> importList(String tableName) async {
    if (global.isWeb) {
      return [];
    }
    if (await checkDBTableExist(tableName)) {
      return await database.rawQuery(
          'SELECT title, path, modified_time, value AS color, background_path FROM $mainDBTableName, $colorDBTableName, ${_tagDBtableName(tableName)} WHERE $mainDBTableName.id = ${_tagDBtableName(tableName)}.id AND $colorDBTableName.id = $mainDBTableName.color ORDER BY sortIdx ASC;');
    }
    return [];
  }

  Future<List<Map>> selectAllDBTable({bool favoriteFilter = false}) async {
    if (global.isWeb) {
      return [];
    }
    String extraQuery = favoriteFilter ? 'WHERE favorite=TRUE' : '';
    var list = await database.rawQuery(
        'SELECT * FROM $tableMasterDBTableName $extraQuery ORDER BY name ASC;');
    return List<Map>.from(list);
  }

  Future<List<Map>> selectAllDBColor() async {
    if (global.isWeb) {
      return [];
    }
    var list = await database.rawQuery(
        'SELECT * FROM $colorDBTableName WHERE id != 0 ORDER BY id ASC;');
    return List<Map>.from(list);
  }

  void toggleDBTableFavorite(String tableName) async {
    if (global.isWeb) {
      return;
    }
    if (await checkDBTableExist(tableName)) {
      bool? fav = await selectDBTableFavorite(tableName);
      if (fav != null) {
        await database.execute(
            'UPDATE $tableMasterDBTableName SET favorite=${!fav} WHERE name="$tableName";');
      }
    }
  }

  Future<bool?> selectDBTableFavorite(String tableName) async {
    if (global.isWeb) {
      return null;
    }
    if (await checkDBTableExist(tableName)) {
      List<Map> data = await database.rawQuery(
          'SELECT favorite FROM $tableMasterDBTableName WHERE name="$tableName";');
      return data[0]['favorite'] == 0 ? false : true;
    }
    return null;
  }

  Future<bool> checkDBTableExist(String tableName) async {
    if (global.isWeb) {
      return false;
    }
    List<Map> data = await database.rawQuery(
        'SELECT name FROM $tableMasterDBTableName WHERE name="$tableName";');
    return data.isNotEmpty;
  }

  void addItemInDBTable(
      {required String tableName, required String trackTitle}) async {
    if (global.isWeb) {
      return;
    }
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
    if (global.isWeb) {
      return;
    }
    if (!(await checkDBTableExist(tableName))) {
      await database.transaction((txn) async {
        await _createDBTable(txn, tableName);
      });
    }
  }

  void updateDBTrackColor(AudioTrack track, VisualizerColor color) async {
    if (global.isWeb) {
      return;
    }
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

  void updateDBTrackBackground(AudioTrack track, String background) async {
    if (global.isWeb) {
      return;
    }
    await database.transaction((txn) async {
      await _insertTrackToDBMainTable(txn, track);
    });
    List<Map> trackData = await database.rawQuery(
        'SELECT id FROM $mainDBTableName WHERE title="${track.title}";');
    if (trackData.isNotEmpty) {
      await database.execute(
          'UPDATE $mainDBTableName SET background_path="$background" WHERE id=${trackData[0]["id"]};');
    }
    AudioStreamController.backgroundFile.add(null);
  }

  Future<AudioTrack?> importTrack(String trackName) async {
    if (global.isWeb) {
      return null;
    }
    List<Map> datas = await database.rawQuery(
        'SELECT title, path, modified_time, value AS color, background_path FROM $mainDBTableName, $colorDBTableName WHERE title="$trackName" AND $colorDBTableName.id = $mainDBTableName.color;');
    if (datas.isNotEmpty) {
      return AudioTrack(
        title: datas[0]['title'],
        path: datas[0]['path'],
        modifiedDateTime: DateTime.parse(datas[0]['modified_time']),
        color: datas[0]['color'],
        background: datas[0]['background_path'],
      );
    }
    return null;
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
        'INSERT OR IGNORE INTO $mainDBTableName(title, path, modified_time) VALUES("${track.title}", "${track.path}", "${track.modifiedDateTime.toString().substring(0, 19)}")';
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
    String? selectedDirectoryPath =
        await FilePicker.platform.getDirectoryPath();
    if (selectedDirectoryPath != null) {
      File file = File(databasesPath);
      file.copySync('$selectedDirectoryPath/$databaseFileName');
    }
  }

  Future<void> importDBFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
    );
    if (result != null) {
      String name = result.files[0].name;
      if (name == databaseFileName) {
        String? path = result.files[0].path;
        if (path != null) {
          File file = File(path);
          File(databasesPath).writeAsBytesSync(file.readAsBytesSync());
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
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (result != null) {
      for (PlatformFile file in result.files) {
        String? path = file.path;
        String tableName = file.name;
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

  Future<void> mainDBToCsv() async {
    String? selectedDirectoryPath =
        await FilePicker.platform.getDirectoryPath();
    if (selectedDirectoryPath != null) {
      List<Map> datas = await database.rawQuery(
          'SELECT title, path, modified_time, value AS color, background_path FROM $mainDBTableName, $colorDBTableName WHERE $colorDBTableName.id = $mainDBTableName.color;');
      File file = File('$selectedDirectoryPath/$mainDBTableName.csv');
      String buffer = '';
      buffer += '"title","path","modified_time","color","background_path"\n';
      for (Map data in datas) {
        buffer +=
            '"${data["title"]}","${data["path"]}","${data["modified_time"]}","${data["color"]}","${data["background_path"]}"\n';
      }
      file.writeAsStringSync(buffer);
    }
  }

  Future<void> mainCsvToDB() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (result != null) {
      String? path = result.files[0].path;
      if (path != null) {
        File file = File(path);
        List<String> datas = file.readAsLinesSync();
        await database.transaction((txn) async {
          int cnt = 0;
          for (String data in datas) {
            if (cnt++ == 0) {
              continue;
            }
            List<String> substrings = data.split(RegExp(r'"'));
            if (substrings.length == 11) {
              await _insertTrackToDBMainTable(
                  txn,
                  AudioTrack(
                    title: substrings[1],
                    path: substrings[3],
                    modifiedDateTime: DateTime.parse(substrings[5]),
                    color: int.parse(substrings[7]),
                    background: substrings[9],
                  ));
            }
          }
        });
      }
    }
  }
}
