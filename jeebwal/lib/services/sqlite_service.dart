import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:get/get.dart';

class SQLiteService extends GetxService {
  late Database _db;
  Database get db => _db;

  @override
  void onInit() {
    super.onInit();
    initDB();
  }

  Future<void> initDB() async {
    final path = join(await getDatabasesPath(), 'jeebwal.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            email TEXT UNIQUE,
            password TEXT,
            academic_number TEXT,
            is_biometric_enabled INTEGER DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER,
            university_name TEXT,
            amount REAL,
            date TEXT,
            status TEXT,
            receipt_no TEXT
          )
        ''');
      },
    );
  }
}
