import 'package:just_audio/just_audio.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import './audio_track.dart';
import './file_audio_source.dart';

class PlayList {
  final Map<String, AudioTrack> _playMap = {};
  final List<String> _playList = [];
  final List<String> _playListBackup = [];
  final String mainDBTableName = '_main';
  final String tableMasterDBTableName = '_table';
  late final Database database;
  int currentIndex = 0;

  int get playListLength => _playMap.length;
  bool get isNotEmpty => _playMap.isNotEmpty;
  String get currentAudioTitle =>
      isNotEmpty ? _playMap[(_playList[currentIndex])]!.title : '';

  String _customDBtableName(String name) => '_fb_$name';

  String audioTitle(int index) => _playMap[_playList[index]]!.title;
  AudioSource audioSource(int index, {bool androidMode = true}) => androidMode
      ? AudioSource.file(_playMap[_playList[index]]!.path)
      : FileAudioSource(
          bytes: _playMap[_playList[index]]!.file!.bytes!.cast<int>());

  void init() async {
    String databasesPath = await getDatabasesPath();
    String path = join(databasesPath, 'audio_track.db');
    database = await openDatabase(path, version: 1,
        onCreate: (Database db, int version) async {
      await db.execute(
          'CREATE TABLE $mainDBTableName (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, title TINYTEXT UNIQUE, path TINYTEXT);');
      await db
          .execute('CREATE TABLE $tableMasterDBTableName (name TEXT UNIQUE);');
    });
  }

  void dispose() async {
    await database.close();
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

  void shuffleOn() {
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
  }

  void shuffleOff() {
    if (_playList.isNotEmpty) {
      String currentKey = _playList[currentIndex];
      for (int i = 0; i < _playList.length; i++) {
        _playList[i] = _playListBackup[i];
        if (currentKey == _playList[i]) {
          currentIndex = i;
        }
      }
    }
  }

  void sortPlayList(int type) {
    if (_playList.isNotEmpty) {
      String currentKey = _playList[currentIndex];
      switch (type) {
        case 0:
          sortByTitleAscending();
          break;
        case 1:
          sortByTitleDescending();
          break;
        case 2:
          sortByChangedDateTimeAscending();
          break;
        case 3:
          sortByChangedDateTimeDescending();
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
  void sortByChangedDateTimeAscending() => _playList.sort((a, b) =>
      _playMap[a]!.changedDateTime.isBefore(_playMap[b]!.changedDateTime)
          ? 1
          : -1);
  void sortByChangedDateTimeDescending() => _playList.sort((a, b) =>
      _playMap[a]!.changedDateTime.isBefore(_playMap[b]!.changedDateTime)
          ? -1
          : 1);

  void clear() {
    _playMap.clear();
    _playList.clear();
    _playListBackup.clear();
    currentIndex = 0;
  }

  void exportList(String tableName) async {
    if (!(await checkDBTableExist(tableName))) {
      await database.transaction((txn) async {
        await createDBTable(txn, tableName);
        await insertListToDBMainTable(txn);
        await insertListToDBCustomTable(txn, tableName);
      });
    }
  }

  void deleteList(String tableName) async {
    if (await checkDBTableExist(tableName)) {
      await database.transaction((txn) async {
        await deleteDBTable(txn, tableName);
      });
    }
  }

  void updateList(String tableName) async {
    if (await checkDBTableExist(tableName)) {
      await database.transaction((txn) async {
        await deleteDBTable(txn, tableName);
        await createDBTable(txn, tableName);
        await insertListToDBMainTable(txn);
        await insertListToDBCustomTable(txn, tableName);
      });
    }
  }

  Future<List<Map>?> importList(String tableName) async {
    if (await checkDBTableExist(tableName)) {
      return await database.rawQuery(
          'SELECT title, path FROM $mainDBTableName, ${_customDBtableName(tableName)} WHERE $mainDBTableName.id = ${_customDBtableName(tableName)}.id;');
    }
    return null;
  }

  Future<void> insertListToDBMainTable(Transaction txn) async {
    for (String trackTitle in _playList) {
      AudioTrack? track = _playMap[trackTitle];
      if (track != null) {
        await txn.rawInsert(
            'INSERT OR IGNORE INTO $mainDBTableName(title, path) VALUES("${track.title}", "${track.path}"');
      }
    }
  }

  Future<void> insertListToDBCustomTable(
      Transaction txn, String tableName) async {
    for (String trackTitle in _playList) {
      AudioTrack? track = _playMap[trackTitle];
      if (track != null) {
        List<Map> data = await txn.rawQuery(
            'SELECT id FROM $mainDBTableName WHERE title = "${track.title}";');
        if (data.isNotEmpty) {
          int id = data[0]['id'];
          await txn.rawInsert(
              'INSERT OR IGNORE INTO ${_customDBtableName(tableName)}(id) VALUES($id);');
        }
      }
    }
  }

  Future<bool> checkDBTableExist(String tableName) async {
    List<Map> data = await database.rawQuery(
        'SELECT name FROM $tableMasterDBTableName WHERE name="$tableName";');
    return data.isNotEmpty;
  }

  Future<List<Map>> selectAllDBTable() async {
    return await database.rawQuery('SELECT name FROM $tableMasterDBTableName');
  }

  Future<void> createDBTable(Transaction txn, String tableName) async {
    txn.rawInsert(
        'CREATE TABLE ${_customDBtableName(tableName)} (id INTEGER NOT NULL PRIMARY KEY);');
    txn.rawInsert(
        'INSERT INTO $tableMasterDBTableName(name) VALUES("$tableName");');
  }

  Future<void> deleteDBTable(Transaction txn, String tableName) async {
    txn.execute('DROP TABLE ${_customDBtableName(tableName)};');
    txn.execute('DELETE FROM $tableMasterDBTableName WHERE name="$tableName";');
  }
}
