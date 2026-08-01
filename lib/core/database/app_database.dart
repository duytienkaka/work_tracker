import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static Database? _database;

  static const int version = 4;

  static Future<Database> database() async {
    if (_database != null) {
      return _database!;
    }

    final path = join(await getDatabasesPath(), "work_tracker.db");

    _database = await openDatabase(
      path,
      version: version,

      onConfigure: (db) async {
        await db.execute("PRAGMA foreign_keys = ON;");
      },

      onCreate: (db, version) async {
        await _createTables(db);
      },

      onUpgrade: (db, oldVersion, newVersion) async {
        await db.execute("DROP TABLE IF EXISTS transactions;");
        await db.execute("DROP TABLE IF EXISTS shifts;");
        await db.execute("DROP TABLE IF EXISTS works;");

        await _createTables(db);
      },
    );

    return _database!;
  }

  static Future<void> _createTables(Database db) async {
    await db.execute("""
CREATE TABLE works(
id TEXT PRIMARY KEY,
name TEXT,
description TEXT,
salaryType INTEGER,
color INTEGER,
icon INTEGER,
isActive INTEGER,
createdAt TEXT
)
""");

    await db.execute("""
CREATE TABLE shifts(
id TEXT PRIMARY KEY,
workId TEXT,
workDate TEXT,
startTime TEXT,
endTime TEXT,
income REAL,
expense REAL,
note TEXT
)
""");

    await db.execute("""
CREATE TABLE transactions(
id TEXT PRIMARY KEY,
shiftId TEXT,
type INTEGER,
category INTEGER,
amount REAL,
note TEXT,
createdAt TEXT
)
""");
  }
}
