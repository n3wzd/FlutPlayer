import 'package:file_picker/file_picker.dart';
import 'dart:io';
import './database_interface.dart';
import './playlist.dart';
import './stream_controller.dart';
import '../models/data.dart';
import '../models/api.dart';

class DatabaseManager {
  DatabaseManager._();
  static final DatabaseManager _instance = DatabaseManager._();
  static DatabaseManager get instance => _instance;

  final String databaseFileName = 'audio_track.db';
  final String mainDBTableName = '_main';
  final String tableMasterDBTableName = '_table';
  final String backgroundDBTableName = '_background';
  late final String databasesPath;

  String _tagDBtableName(String name) => '_tag_${name.replaceAll(' ', '_')}';

  Future<void> init() async {
    final path = await DatabaseInterface.instance.getDatabasesPath();
    databasesPath = '$path/$databaseFileName';
    await DatabaseInterface.instance.openDatabaseFile(databasesPath);

    await DatabaseInterface.instance.execute(
        'CREATE TABLE IF NOT EXISTS $mainDBTableName (title TEXT PRIMARY KEY, path TEXT NOT NULL, modified_time TEXT, color TEXT);');
    await DatabaseInterface.instance.execute(
        'CREATE TABLE IF NOT EXISTS $tableMasterDBTableName (name TEXT PRIMARY KEY, favorite INTEGER NOT NULL DEFAULT 0);');
    await DatabaseInterface.instance.execute(
        'CREATE TABLE IF NOT EXISTS $backgroundDBTableName (track TEXT PRIMARY KEY, path TEXT NOT NULL, rotate BOOL NOT NULL DEFAULT FALSE, scale INTEGER NOT NULL DEFAULT 0, color INTEGER NOT NULL DEFAULT 0, value INTEGER NOT NULL DEFAULT 75);');
  }

  void dispose() {
    DatabaseInterface.instance.dispose();
  }

  Future<void> exportList(String tableName, bool autoAddPlaylist) async {
    if (!(await checkDBTableExist(tableName))) {
      await DatabaseInterface.instance.transaction((txn) async {
        await _createDBTable(txn, tableName);
        if (autoAddPlaylist) {
          await _insertListToDBTagTable(txn, tableName);
        }
      });
    }
  }

  Future<void> deleteList(String tableName) async {
    if (await checkDBTableExist(tableName)) {
      await DatabaseInterface.instance.transaction((txn) async {
        await _deleteDBTable(txn, tableName);
      });
    }
  }

  Future<void> updateList(String tableName) async {
    if (await checkDBTableExist(tableName)) {
      await DatabaseInterface.instance.transaction((txn) async {
        await _deleteDBTable(txn, tableName);
        await _createDBTable(txn, tableName);
        await _insertListToDBTagTable(txn, tableName);
      });
    }
  }

  Future<List<Map>> importList(String tableName) async {
    if (await checkDBTableExist(tableName)) {
      return await DatabaseInterface.instance.rawQuery(
          'SELECT $mainDBTableName.title, path, modified_time, color FROM $mainDBTableName, ${_tagDBtableName(tableName)} WHERE $mainDBTableName.title = ${_tagDBtableName(tableName)}.title ORDER BY sortIdx ASC;');
    }
    return [];
  }

  Future<List<Map>> selectAllDBTable({bool favoriteFilter = false}) async {
    String extraQuery = favoriteFilter ? 'WHERE favorite=1' : '';
    var list = await DatabaseInterface.instance.rawQuery(
        'SELECT * FROM $tableMasterDBTableName $extraQuery ORDER BY name ASC;');
    return List<Map>.from(list);
  }

  Future<void> toggleDBTableFavorite(String tableName) async {
    if (await checkDBTableExist(tableName)) {
      bool? fav = await selectDBTableFavorite(tableName);
      if (fav != null) {
        await DatabaseInterface.instance.execute(
            'UPDATE $tableMasterDBTableName SET favorite=${fav ? 0 : 1} WHERE name="$tableName";');
      }
    }
  }

  Future<bool?> selectDBTableFavorite(String tableName) async {
    if (await checkDBTableExist(tableName)) {
      List<Map> data = await DatabaseInterface.instance.rawQuery(
          'SELECT favorite FROM $tableMasterDBTableName WHERE name="$tableName";');
      return data[0]['favorite'] == 1 ? true : false;
    }
    return null;
  }

  Future<bool> checkDBTableExist(String tableName) async {
    List<Map> data = await DatabaseInterface.instance.rawQuery(
        'SELECT name FROM $tableMasterDBTableName WHERE name="$tableName";');
    return data.isNotEmpty;
  }

  Future<void> addTrackInDBTable(
      {required String tableName, required String trackTitle}) async {
    AudioTrack? track = PlayList.instance.playMap[trackTitle];
    if (track != null) {
      if (await checkDBTableExist(tableName)) {
        await DatabaseInterface.instance.transaction((txn) async {
          await _insertTrackToDBMainTable(txn, track);
          await _insertTrackToDBTagTable(txn, tableName, track.title);
        });
      }
    }
  }

  Future<void> createDBTable(String tableName) async {
    if (!(await checkDBTableExist(tableName))) {
      await DatabaseInterface.instance.transaction((txn) async {
        await _createDBTable(txn, tableName);
      });
    }
  }

  Future<void> updateDBTrackColor(AudioTrack track, String color) async {
    await DatabaseInterface.instance.transaction((txn) async {
      await _insertTrackToDBMainTable(txn, track);
    });
    await DatabaseInterface.instance.execute(
        'UPDATE $mainDBTableName SET color="$color" WHERE title="${track.title}";');
    AudioStreamController.visualizerColor.add(null);
  }

  Future<void> updateDBTrackBackground(
      String trackTitle, BackgroundData data) async {
    await DatabaseInterface.instance.transaction((txn) async {
      await _insertDataToDBBackgroundTable(txn, trackTitle, data);
    });
    await DatabaseInterface.instance.execute(
        'UPDATE $backgroundDBTableName SET path="${data.path}", rotate=${data.rotate ? 1 : 0}, scale=${data.scale ? 1 : 0}, color=${data.color ? 1 : 0}, value=${data.value} WHERE track="$trackTitle";');
    AudioStreamController.backgroundFile.add(null);
  }

  Future<AudioTrack?> importTrack(String trackName) async {
    List<Map> datas = await DatabaseInterface.instance.rawQuery(
        'SELECT title, path, modified_time, color FROM $mainDBTableName WHERE title="$trackName";');
    if (datas.isNotEmpty) {
      return AudioTrack(
        title: datas[0]['title'],
        path: datas[0]['path'],
        modifiedDateTime: datas[0]['modified_time'],
        color: datas[0]['color'],
        background: await _importBackground(trackName),
      );
    }
    return null;
  }

  Future<BackgroundData?> _importBackground(String trackName) async {
    List<Map> datas = await DatabaseInterface.instance.rawQuery(
        'SELECT path, rotate, scale, color, value FROM $backgroundDBTableName WHERE track="$trackName";');
    if (datas.isNotEmpty) {
      return BackgroundData(
        path: datas[0]['path'],
        rotate: datas[0]['rotate'] == 1 ? true : false,
        scale: datas[0]['scale'] == 1 ? true : false,
        color: datas[0]['color'] == 1 ? true : false,
        value: datas[0]['value'],
      );
    }
    return null;
  }

  Future<void> _insertListToDBTagTable(txn, String tableName) async {
    for (String trackTitle in PlayList.instance.playList) {
      AudioTrack? track = PlayList.instance.playMap[trackTitle];
      if (track != null) {
        await _insertTrackToDBMainTable(txn, track);
        await _insertTrackToDBTagTable(txn, tableName, track.title);
      }
    }
  }

  Future<void> _insertTrackToDBMainTable(txn, AudioTrack track) async {
    String sql =
        'INSERT OR IGNORE INTO $mainDBTableName(title, path, modified_time, color) VALUES("${track.title}", "${track.path}", "${track.modifiedDateTime}", "${track.color}")';
    if (txn != null) {
      await txn.rawInsert(sql);
    } else {
      await DatabaseInterface.instance.rawQuery(sql);
    }
  }

  Future<void> _insertTrackToDBTagTable(
      txn, String tableName, String title) async {
    List<Map> data = await txn
        .rawQuery('SELECT * FROM $mainDBTableName WHERE title = "$title";');
    if (data.isNotEmpty) {
      await txn.rawInsert(
          'INSERT OR IGNORE INTO ${_tagDBtableName(tableName)}(title) VALUES("$title");');
    }
  }

  Future<void> _insertDataToDBBackgroundTable(
      txn, String trackTitle, BackgroundData data) async {
    String sql =
        'INSERT OR IGNORE INTO $backgroundDBTableName(track, path, rotate, scale, color, value) VALUES("$trackTitle", "${data.path}", ${data.rotate ? 1 : 0}, ${data.scale ? 1 : 0}, ${data.color ? 1 : 0}, ${data.value})';
    if (txn != null) {
      await txn.rawInsert(sql);
    } else {
      await DatabaseInterface.instance.rawQuery(sql);
    }
  }

  Future<void> _createDBTable(txn, String tableName) async {
    txn.rawInsert(
        'CREATE TABLE ${_tagDBtableName(tableName)} (sortIdx INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT UNIQUE);');
    txn.rawInsert(
        'INSERT INTO $tableMasterDBTableName(name) VALUES("$tableName");');
  }

  Future<void> _deleteDBTable(txn, String tableName) async {
    txn.execute('DROP TABLE ${_tagDBtableName(tableName)};');
    txn.execute('DELETE FROM $tableMasterDBTableName WHERE name="$tableName";');
  }

  Future<APIResult> exportDBFile() async {
    bool success = true;
    String msg = '';
    try {
      String? selectedDirectoryPath =
          await FilePicker.platform.getDirectoryPath();
      if (selectedDirectoryPath != null) {
        File file = File(databasesPath);
        file.copySync('$selectedDirectoryPath/$databaseFileName');
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

  Future<APIResult> importDBFile() async {
    bool success = true;
    String msg = '';
    try {
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
      } else {
        success = false;
        msg = 'No File Chosen.';
      }
    } catch (e) {
      success = false;
      msg = e.toString();
    }
    return APIResult(success: success, msg: msg);
  }

  Future<APIResult> tagDBToCsv() async {
    bool success = true;
    String msg = '';
    try {
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

  Future<APIResult> tagCsvToDB() async {
    bool success = true;
    String msg = '';
    try {
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
              await DatabaseInterface.instance.transaction((txn) async {
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
      } else {
        success = false;
        msg = 'No File Chosen.';
      }
    } catch (e) {
      success = false;
      msg = e.toString();
    }
    return APIResult(success: success, msg: msg);
  }

  Future<APIResult> mainDBToCsv() async {
    bool success = true;
    String msg = '';
    try {
      String? selectedDirectoryPath =
          await FilePicker.platform.getDirectoryPath();
      if (selectedDirectoryPath != null) {
        List<Map> datas = await DatabaseInterface.instance.rawQuery(
            'SELECT title, path, modified_time, color FROM $mainDBTableName;');
        File file = File('$selectedDirectoryPath/$mainDBTableName.csv');
        String buffer = '';
        buffer += '"title","path","modified_time","color"\n';
        for (Map data in datas) {
          buffer +=
              '"${data["title"]}","${data["path"]}","${data["modified_time"]}","${data["color"]}"\n';
        }
        file.writeAsStringSync(buffer);
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

  Future<APIResult> mainCsvToDB() async {
    bool success = true;
    String msg = '';
    try {
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
          await DatabaseInterface.instance.transaction((txn) async {
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
                      modifiedDateTime: substrings[5],
                      color: substrings[7],
                    ));
              }
            }
          });
        }
      } else {
        success = false;
        msg = 'No Files Chosen.';
      }
    } catch (e) {
      success = false;
      msg = e.toString();
    }
    return APIResult(success: success, msg: msg);
  }
}
