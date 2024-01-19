import 'package:sqflite_common_ffi/sqflite_ffi.dart' as sqflite_ffi;

class DatabaseInterface {
  DatabaseInterface._();
  static final DatabaseInterface _instance = DatabaseInterface._();
  static DatabaseInterface get instance => _instance;

  late final sqflite_ffi.Database databaseFfi;
  late final bool activeDatabase;
  late final bool usingFfi;

  dynamic get database => databaseFfi;

  void init() {
    sqflite_ffi.sqfliteFfiInit();
    sqflite_ffi.databaseFactory = sqflite_ffi.databaseFactoryFfi;
  }

  void dispose() {
    databaseFfi.close();
  }

  Future<String> getDatabasesPath() async {
    return sqflite_ffi.getDatabasesPath();
  }

  Future<void> openDatabaseFile(String databasesPath) async {
    databaseFfi =
            await sqflite_ffi.databaseFactoryFfi.openDatabase(databasesPath);
  }

  Future<bool> databaseExists(String path) async {
    return await sqflite_ffi.databaseExists(path);
  }

  Future<void> execute(String sql) async {
    await database.execute(sql);
  }

  Future<List<Map>> rawQuery(String sql) async {
    return await database.rawQuery(sql);
  }

  Future<void> transaction(action) async {
    await database.transaction(action);
  }
}
