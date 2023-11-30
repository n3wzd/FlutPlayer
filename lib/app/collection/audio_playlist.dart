import 'package:just_audio/just_audio.dart';
import 'package:sqflite/sqflite.dart';
import 'package:file_picker/file_picker.dart';
import './audio_track.dart';
import './file_audio_source.dart';
import './preference.dart';
import 'dart:io';

import '../log.dart' as log;

class PlayList {
  final Map<String, AudioTrack> _playMap = {};
  final List<String> _playList = [];
  final List<String> _playListBackup = [];
  final String databaseFileName = 'audio_track.db';
  final String mainDBTableName = '_main';
  final String tableMasterDBTableName = '_table';
  late final Database database;
  late final String databasesPath;
  bool isDBOpen = false;
  PlayListOrderState _playListOrderState = PlayListOrderState.none;

  int currentIndex = 0;

  int get playListLength => _playMap.length;
  bool get isNotEmpty => _playMap.isNotEmpty;
  String get currentAudioTitle =>
      isNotEmpty ? _playMap[(_playList[currentIndex])]!.title : '';
  PlayListOrderState get playListOrderState => _playListOrderState;
  AudioTrack? get currentAudioTrack =>
      isNotEmpty ? _playMap[(_playList[currentIndex])]! : null;

  String _customDBtableName(String name) => '_fb_${name.replaceAll(' ', '_')}';

  String audioTitle(int index) => _playMap[_playList[index]]!.title;
  AudioSource audioSource(int index, {bool androidMode = true}) => androidMode
      ? AudioSource.file(_playMap[_playList[index]]!.path)
      : FileAudioSource(
          bytes: _playMap[_playList[index]]!.file!.bytes!.cast<int>());

  void init() async {
    log.debugLog = '';
    try {
      final path = await getDatabasesPath();
      databasesPath = '$path/$databaseFileName';
      if (await databaseExists(databasesPath)) {
        database = await openDatabase(databasesPath);
      } else {
        database = await openDatabase(databasesPath);
        await database.execute(
            'CREATE TABLE $mainDBTableName (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, title TINYTEXT UNIQUE, path TINYTEXT);');
        await database.execute(
            'CREATE TABLE $tableMasterDBTableName (name TEXT NOT NULL UNIQUE, favorite BOOL NOT NULL DEFAULT FALSE);');
      }
      isDBOpen = true;
    } catch (e) {
      log.debugLog += e.toString();
    }
    log.debugLog += isDBOpen.toString();
    log.debugLogStreamController.add(null);
  }

  void dispose() {
    database.close();
  }

  void addAll(List<AudioTrack> files) {
    for (AudioTrack file in files) {
      String key = file.title;
      if (!_playMap.containsKey(key)) {
        _playMap[key] = file;
        _playList.add(key);
        _playListBackup.add(key);
      }
    }
  }

  void shift(int oldIndex, int newIndex) {
    if (currentIndex == oldIndex) {
      currentIndex = newIndex;
    } else if (currentIndex == newIndex) {
      if (currentIndex > oldIndex) {
        currentIndex = newIndex - 1;
      } else {
        currentIndex = newIndex + 1;
      }
    } else if (currentIndex > oldIndex && currentIndex < newIndex) {
      currentIndex -= 1;
    } else if (currentIndex < oldIndex && currentIndex > newIndex) {
      currentIndex += 1;
    }
    _playList.insert(newIndex, _playList.removeAt(oldIndex));
    _playListBackup.insert(newIndex, _playListBackup.removeAt(oldIndex));
  }

  void remove(int index) {
    if (currentIndex > index) {
      currentIndex -= 1;
    }
    _playMap.remove(_playList.removeAt(index));
    _playListBackup.removeAt(index);
  }

  void shuffle() {
    if (_playList.isNotEmpty) {
      String currentKey = _playList[currentIndex];
      _playList.shuffle();
      for (int i = 0; i < _playList.length; i++) {
        if (currentKey == _playList[i]) {
          String tempKey = _playList[0];
          _playList[0] = _playList[i];
          _playList[i] = tempKey;
          break;
        }
      }
      currentIndex = 0;
    }
    _playListOrderState = PlayListOrderState.shuffled;
  }

  void rollback() {
    if (_playList.isNotEmpty) {
      String currentKey = _playList[currentIndex];
      for (int i = 0; i < _playList.length; i++) {
        _playList[i] = _playListBackup[i];
        if (currentKey == _playList[i]) {
          currentIndex = i;
        }
      }
    }
    _playListOrderState = PlayListOrderState.none;
  }

  void toggleShuffleMode() {
    if (_playList.isNotEmpty) {
      if (_playListOrderState == PlayListOrderState.shuffled) {
        rollback();
      } else {
        shuffle();
      }
    }
  }

  void sortPlayList() {
    if (_playList.isNotEmpty) {
      if (_playListOrderState == PlayListOrderState.ascending) {
        _playListOrderState = PlayListOrderState.descending;
      } else if (_playListOrderState == PlayListOrderState.descending) {
        _playListOrderState = PlayListOrderState.none;
      } else {
        _playListOrderState = PlayListOrderState.ascending;
      }

      if (_playListOrderState == PlayListOrderState.none) {
        rollback();
        return;
      }

      String currentKey = _playList[currentIndex];
      switch (Preference.playListOrderMethod) {
        case PlayListOrderMethod.title:
          _playListOrderState == PlayListOrderState.ascending
              ? sortByTitleAscending()
              : sortByTitleDescending();
          break;
        case PlayListOrderMethod.modifiedDateTime:
          _playListOrderState == PlayListOrderState.ascending
              ? sortByModifiedDateTimeAscending()
              : sortByModifiedDateTimeDescending();
          break;
        default:
          break;
      }
      for (int i = 0; i < _playList.length; i++) {
        if (currentKey == _playList[i]) {
          currentIndex = i;
          break;
        }
      }
    }
  }

  void sortByTitleAscending() => _playList.sort((a, b) => a.compareTo(b));
  void sortByTitleDescending() => _playList.sort((a, b) => b.compareTo(a));
  void sortByModifiedDateTimeAscending() => _playList.sort((a, b) =>
      _playMap[a]!.modifiedDateTime.isBefore(_playMap[b]!.modifiedDateTime)
          ? 1
          : -1);
  void sortByModifiedDateTimeDescending() => _playList.sort((a, b) =>
      _playMap[a]!.modifiedDateTime.isBefore(_playMap[b]!.modifiedDateTime)
          ? -1
          : 1);

  void clear() {
    _playMap.clear();
    _playList.clear();
    _playListBackup.clear();
    currentIndex = 0;
    _playListOrderState = PlayListOrderState.none;
  }

  void exportList(String tableName, bool autoAddPlaylist) async {
    if (!(await checkDBTableExist(tableName))) {
      await database.transaction((txn) async {
        await _createDBTable(txn, tableName);
        if (autoAddPlaylist) {
          await _insertListToDBCustomTable(txn, tableName);
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
        await _insertListToDBCustomTable(txn, tableName);
      });
    }
  }

  Future<List<Map>> importList(String tableName) async {
    if (await checkDBTableExist(tableName)) {
      return await database.rawQuery(
          'SELECT title, path FROM $mainDBTableName, ${_customDBtableName(tableName)} WHERE $mainDBTableName.id = ${_customDBtableName(tableName)}.id ORDER BY sortIdx ASC;');
    }
    return [];
  }

  Future<List<Map>> selectAllDBTable({bool favoriteFilter = false}) async {
    String extraQuery = favoriteFilter ? 'WHERE favorite=TRUE' : '';
    return await database.rawQuery(
        'SELECT * FROM $tableMasterDBTableName $extraQuery ORDER BY name ASC;');
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
    if (!isDBOpen) {
      return;
    }
    AudioTrack? track = _playMap[trackTitle];
    if (track != null) {
      if (await checkDBTableExist(tableName)) {
        await database.transaction((txn) async {
          await _insertTrackToDBMainTable(txn, track);
          await _insertTrackToDBCustomTable(txn, tableName, track.title);
        });
      }
    }
  }

  void createDBTable(String tableName) async {
    if (!isDBOpen) {
      return;
    }
    if (!(await checkDBTableExist(tableName))) {
      await database.transaction((txn) async {
        await _createDBTable(txn, tableName);
      });
    }
  }

  Future<void> _insertListToDBCustomTable(
      Transaction txn, String tableName) async {
    for (String trackTitle in _playList) {
      AudioTrack? track = _playMap[trackTitle];
      if (track != null) {
        await _insertTrackToDBMainTable(txn, track);
        await _insertTrackToDBCustomTable(txn, tableName, track.title);
      }
    }
  }

  Future<void> _insertTrackToDBMainTable(
      Transaction txn, AudioTrack track) async {
    await txn.rawInsert(
        'INSERT OR IGNORE INTO $mainDBTableName(title, path) VALUES("${track.title}", "${track.path}")');
  }

  Future<void> _insertTrackToDBCustomTable(
      Transaction txn, String tableName, String title) async {
    List<Map> data = await txn
        .rawQuery('SELECT id FROM $mainDBTableName WHERE title = "$title";');
    if (data.isNotEmpty) {
      int id = data[0]['id'];
      await txn.rawInsert(
          'INSERT OR IGNORE INTO ${_customDBtableName(tableName)}(id) VALUES($id);');
    }
  }

  Future<void> _createDBTable(Transaction txn, String tableName) async {
    txn.rawInsert(
        'CREATE TABLE ${_customDBtableName(tableName)} (sortIdx INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, id INTEGER NOT NULL UNIQUE);');
    txn.rawInsert(
        'INSERT INTO $tableMasterDBTableName(name) VALUES("$tableName");');
  }

  Future<void> _deleteDBTable(Transaction txn, String tableName) async {
    txn.execute('DROP TABLE ${_customDBtableName(tableName)};');
    txn.execute('DELETE FROM $tableMasterDBTableName WHERE name="$tableName";');
  }

  Future<void> exportDBFile() async {
    if (!isDBOpen) {
      return;
    }
    String? selectedDirectoryPath =
        await FilePicker.platform.getDirectoryPath();
    if (selectedDirectoryPath != null) {
      File file = File(databasesPath);
      file.copy('$selectedDirectoryPath/$databaseFileName');
    }
  }

  Future<void> customTableDatabaseToCsv() async {
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

  Future<void> customTableCsvToDatabase() async {
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
              await _insertTrackToDBCustomTable(
                  txn, tableName, data.substring(1, data.length - 1));
            }
          });
        }
      }
    }
  }
}

enum PlayListOrderState {
  none,
  ascending,
  descending,
  shuffled,
}

enum PlayListOrderMethod {
  title('title'),
  modifiedDateTime('modifiedDateTime'),
  undefined('undefined');

  const PlayListOrderMethod(this.code);
  final String code;

  factory PlayListOrderMethod.toEnum(String code) {
    return PlayListOrderMethod.values.firstWhere((value) => value.code == code,
        orElse: () => PlayListOrderMethod.undefined);
  }

  @override
  String toString() {
    return code;
  }
}
