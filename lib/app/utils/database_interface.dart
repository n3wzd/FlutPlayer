import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as sqflite_ffi;
import '../global.dart' as global;

class DatabaseInterface {
  DatabaseInterface._();
  static final DatabaseInterface _instance = DatabaseInterface._();
  static DatabaseInterface get instance => _instance;

  late final sqflite.Database databaseSqflite;
  late final sqflite_ffi.Database databaseFfi;
  late final bool activeDatabase;
  late final bool usingFfi;

  dynamic get database => usingFfi ? databaseFfi : databaseSqflite;

  void init() {
    activeDatabase = !global.isWeb;
    usingFfi = global.isWindows;

    if (activeDatabase && usingFfi) {
      sqflite_ffi.sqfliteFfiInit();
      sqflite_ffi.databaseFactory = sqflite_ffi.databaseFactoryFfi;
    }
  }

  void dispose() {
    if (activeDatabase) {
      databaseSqflite.close();
      databaseFfi.close();
    }
  }

  Future<String> getDatabasesPath() async {
    if (activeDatabase) {
      return usingFfi
          ? sqflite_ffi.getDatabasesPath()
          : sqflite.getDatabasesPath();
    }

    return '';
  }

  Future<void> openDatabaseFile(String databasesPath) async {
    if (activeDatabase) {
      if (usingFfi) {
        databaseFfi =
            await sqflite_ffi.databaseFactoryFfi.openDatabase(databasesPath);
      } else {
        databaseSqflite = await sqflite.openDatabase(databasesPath);
      }
    }
  }

  Future<bool> databaseExists(String path) async {
    if (activeDatabase) {
      bool res = await (usingFfi
          ? sqflite_ffi.databaseExists(path)
          : sqflite.databaseExists(path));
      return res;
    }
    return false;
  }

  Future<void> execute(String sql) async {
    if (activeDatabase) {
      await database.execute(sql);
    }
  }

  Future<List<Map>> rawQuery(String sql) async {
    if (activeDatabase) {
      return await database.rawQuery(sql);
    }
    return [];
  }

  Future<void> transaction(action) async {
    if (activeDatabase) {
      await database.transaction(action);
    }
  }
}
