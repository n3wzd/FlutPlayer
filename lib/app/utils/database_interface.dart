import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as sqflite_ffi;
import './platform_support.dart';

class DatabaseInterface {
  DatabaseInterface._();
  static final DatabaseInterface _instance = DatabaseInterface._();
  static DatabaseInterface get instance => _instance;

  sqflite.Database? _databaseSqflite;
  sqflite_ffi.Database? _databaseFfi;

  bool get _useFfi => PlatformSupport.isWindows;
  bool get isOpen => _useFfi ? _databaseFfi != null : _databaseSqflite != null;
  dynamic get _database => _useFfi ? _databaseFfi! : _databaseSqflite!;

  void init() {
    if (_useFfi) {
      sqflite_ffi.sqfliteFfiInit();
      sqflite_ffi.databaseFactory = sqflite_ffi.databaseFactoryFfi;
    }
  }

  void dispose() {
    if (isOpen) {
      _database.close();
      _databaseSqflite = null;
      _databaseFfi = null;
    }
  }

  Future<String> getDatabasesPath() async {
    if (_useFfi) {
      return sqflite_ffi.getDatabasesPath();
    }
    return sqflite.getDatabasesPath();
  }

  Future<void> openDatabaseFile(String databasesPath) async {
    if (isOpen) {
      return;
    }
    if (_useFfi) {
      _databaseFfi = await sqflite_ffi.databaseFactoryFfi.openDatabase(
        databasesPath,
      );
    } else {
      _databaseSqflite = await sqflite.openDatabase(databasesPath);
    }
  }

  Future<bool> databaseExists(String path) async {
    if (_useFfi) {
      return await sqflite_ffi.databaseExists(path);
    }
    return await sqflite.databaseExists(path);
  }

  Future<void> execute(String sql) async {
    if (!isOpen) return;
    await _database.execute(sql);
  }

  Future<List<Map>> rawQuery(String sql) async {
    if (!isOpen) return [];
    return await _database.rawQuery(sql);
  }

  Future<void> transaction(Future<void> Function(dynamic) action) async {
    if (!isOpen) return;
    await _database.transaction(action);
  }
}
