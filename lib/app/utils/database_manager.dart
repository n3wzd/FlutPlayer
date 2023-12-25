import 'package:file_picker/file_picker.dart';
import 'dart:io';
import './database_interface.dart';
import './playlist.dart';
import './stream_controller.dart';
import '../models/audio_track.dart';
import '../global.dart' as global;

class DatabaseManager {
  DatabaseManager._();
  static final DatabaseManager _instance = DatabaseManager._();
  static DatabaseManager get instance => _instance;

  final String databaseFileName = 'audio_track.db';
  final String mainDBTableName = '_main';
  final String tableMasterDBTableName = '_table';
  late final String databasesPath;

  String _tagDBtableName(String name) => '_tag_${name.replaceAll(' ', '_')}';

  void init() async {
    DatabaseInterface.instance.init();
    final path = await DatabaseInterface.instance.getDatabasesPath();
    databasesPath = '$path/$databaseFileName';
    await DatabaseInterface.instance.openDatabaseFile(databasesPath);

    if (!(await DatabaseInterface.instance.databaseExists(databasesPath))) {
      await DatabaseInterface.instance.execute(
          'CREATE TABLE IF NOT EXISTS $mainDBTableName (title TEXT PRIMARY KEY, path TEXT NOT NULL, modified_time TEXT, color TEXT, background_path TEXT);');
      await DatabaseInterface.instance.execute(
          'CREATE TABLE IF NOT EXISTS $tableMasterDBTableName (name TEXT PRIMARY KEY, favorite BOOL NOT NULL DEFAULT FALSE);');
    }
  }

  void dispose() {
    DatabaseInterface.instance.dispose();
  }

  void exportList(String tableName, bool autoAddPlaylist) async {
    if (global.isWeb) {
      return;
    }
    if (!(await checkDBTableExist(tableName))) {
      await DatabaseInterface.instance.transaction((txn) async {
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
      await DatabaseInterface.instance.transaction((txn) async {
        await _deleteDBTable(txn, tableName);
      });
    }
  }

  void updateList(String tableName) async {
    if (global.isWeb) {
      return;
    }
    if (await checkDBTableExist(tableName)) {
      await DatabaseInterface.instance.transaction((txn) async {
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
      return await DatabaseInterface.instance.rawQuery(
          'SELECT $mainDBTableName.title, path, modified_time, color, background_path FROM $mainDBTableName, ${_tagDBtableName(tableName)} WHERE $mainDBTableName.title = ${_tagDBtableName(tableName)}.title ORDER BY sortIdx ASC;');
    }
    return [];
  }

  Future<List<Map>> selectAllDBTable({bool favoriteFilter = false}) async {
    if (global.isWeb) {
      return [];
    }
    String extraQuery = favoriteFilter ? 'WHERE favorite=TRUE' : '';
    var list = await DatabaseInterface.instance.rawQuery(
        'SELECT * FROM $tableMasterDBTableName $extraQuery ORDER BY name ASC;');
    return List<Map>.from(list);
  }

  void toggleDBTableFavorite(String tableName) async {
    if (global.isWeb) {
      return;
    }
    if (await checkDBTableExist(tableName)) {
      bool? fav = await selectDBTableFavorite(tableName);
      if (fav != null) {
        await DatabaseInterface.instance.execute(
            'UPDATE $tableMasterDBTableName SET favorite=${!fav} WHERE name="$tableName";');
      }
    }
  }

  Future<bool?> selectDBTableFavorite(String tableName) async {
    if (global.isWeb) {
      return null;
    }
    if (await checkDBTableExist(tableName)) {
      List<Map> data = await DatabaseInterface.instance.rawQuery(
          'SELECT favorite FROM $tableMasterDBTableName WHERE name="$tableName";');
      return data[0]['favorite'] == 0 ? false : true;
    }

    return null;
  }

  Future<bool> checkDBTableExist(String tableName) async {
    if (global.isWeb) {
      return false;
    }
    List<Map> data = await DatabaseInterface.instance.rawQuery(
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
        await DatabaseInterface.instance.transaction((txn) async {
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
      await DatabaseInterface.instance.transaction((txn) async {
        await _createDBTable(txn, tableName);
      });
    }
  }

  void updateDBTrackColor(AudioTrack track, String color) async {
    if (global.isWeb) {
      return;
    }
    await DatabaseInterface.instance.transaction((txn) async {
      await _insertTrackToDBMainTable(txn, track);
    });
    await DatabaseInterface.instance.execute(
        'UPDATE $mainDBTableName SET color="$color" WHERE title="${track.title}";');
    AudioStreamController.visualizerColor.add(null);
  }

  void updateDBTrackBackground(AudioTrack track, String background) async {
    if (global.isWeb) {
      return;
    }
    await DatabaseInterface.instance.transaction((txn) async {
      await _insertTrackToDBMainTable(txn, track);
    });
    await DatabaseInterface.instance.execute(
        'UPDATE $mainDBTableName SET background_path="$background" WHERE title="${track.title}";');
    AudioStreamController.backgroundFile.add(null);
  }

  Future<AudioTrack?> importTrack(String trackName) async {
    if (global.isWeb) {
      return null;
    }
    List<Map> datas = await DatabaseInterface.instance.rawQuery(
        'SELECT title, path, modified_time, color, background_path FROM $mainDBTableName WHERE title="$trackName";');
    if (datas.isNotEmpty) {
      return AudioTrack(
        title: datas[0]['title'],
        path: datas[0]['path'],
        modifiedDateTime: datas[0]['modified_time'],
        color: datas[0]['color'],
        background: datas[0]['background_path'],
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
        'INSERT OR IGNORE INTO $mainDBTableName(title, path, modified_time, color, background_path) VALUES("${track.title}", "${track.path}", "${track.modifiedDateTime}", "${track.color}", "${track.background}")';
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
    }
  }

  Future<void> mainDBToCsv() async {
    String? selectedDirectoryPath =
        await FilePicker.platform.getDirectoryPath();
    if (selectedDirectoryPath != null) {
      List<Map> datas = await DatabaseInterface.instance.rawQuery(
          'SELECT title, path, modified_time, color, background_path FROM $mainDBTableName;');
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
                    background: substrings[9],
                  ));
            }
          }
        });
      }
    }
  }
}
