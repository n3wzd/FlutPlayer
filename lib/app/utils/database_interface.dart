import 'package:sqflite/sqflite.dart' as sqflite;

class DatabaseInterface {
  DatabaseInterface._();
  static final DatabaseInterface _instance = DatabaseInterface._();
  static DatabaseInterface get instance => _instance;

  late final sqflite.Database databaseSqflite;

  void dispose() {
    databaseSqflite.close();
  }

  Future<String> getDatabasesPath() async {
    return sqflite.getDatabasesPath();
  }

  Future<void> openDatabaseFile(String databasesPath) async {
    databaseSqflite = await sqflite.openDatabase(databasesPath);
  }

  Future<bool> databaseExists(String path) async {
    return await sqflite.databaseExists(path);
  }

  Future<void> execute(String sql) async {
    await databaseSqflite.execute(sql);
  }

  Future<List<Map>> rawQuery(String sql) async {
    return await databaseSqflite.rawQuery(sql);
  }

  Future<void> transaction(action) async {
    databaseSqflite.transaction(action);
  }
}
