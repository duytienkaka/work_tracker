import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static Database? _database;
  static Future<Database>? _databaseFuture;

  static const int version = 7;

  static Future<Database> database() async {
    if (_database != null) {
      return _database!;
    }

    _databaseFuture ??= _openDatabase();
    try {
      return await _databaseFuture!;
    } catch (_) {
      _databaseFuture = null;
      rethrow;
    }
  }

  static Future<Database> _openDatabase() async {
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
        if (oldVersion < 7) {
          await _migrateExpenseTable(db);
        }

        if (oldVersion < 6) {
          await _migrateIncomeTable(db);
        }

        if (oldVersion < 5) {
          await db.execute("DROP TABLE IF EXISTS transactions;");
          await db.execute("DROP TABLE IF EXISTS shifts;");
          await db.execute("DROP TABLE IF EXISTS works;");
          await _createTables(db);
          return;
        }
      },
    );

    return _database!;
  }

  static Future<void> _createTables(Database db) async {
    await db.execute("""
CREATE TABLE IF NOT EXISTS works(
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
CREATE TABLE IF NOT EXISTS shifts(
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
CREATE TABLE IF NOT EXISTS transactions(
id TEXT PRIMARY KEY,
shiftId TEXT,
type INTEGER,
category INTEGER,
amount REAL,
note TEXT,
createdAt TEXT
)
""");

    await db.execute("""
CREATE TABLE IF NOT EXISTS income(
id TEXT PRIMARY KEY,
shift_id TEXT NOT NULL,
title TEXT NOT NULL,
amount REAL NOT NULL,
tip REAL NOT NULL DEFAULT 0,
note TEXT,
created_at TEXT NOT NULL,
updated_at TEXT
)
""");

    await db.execute("""
CREATE TABLE IF NOT EXISTS expense(
id TEXT PRIMARY KEY,
shift_id TEXT NOT NULL,
title TEXT NOT NULL,
amount REAL NOT NULL,
note TEXT,
created_at TEXT NOT NULL,
updated_at TEXT
)
""");
  }

  static Future<void> _migrateIncomeTable(Database db) async {
    final tableExists = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='income'",
    );

    if (tableExists.isEmpty) {
      await db.execute("""
CREATE TABLE IF NOT EXISTS income(
id TEXT PRIMARY KEY,
shift_id TEXT NOT NULL,
title TEXT NOT NULL,
amount REAL NOT NULL,
tip REAL NOT NULL DEFAULT 0,
note TEXT,
created_at TEXT NOT NULL,
updated_at TEXT
)
""");
      return;
    }

    final columns = await db.rawQuery("PRAGMA table_info(income)");
    final columnNames = columns.map((column) => column['name']).toSet();

    if (!columnNames.contains('title')) {
      await db.execute(
        "ALTER TABLE income ADD COLUMN title TEXT NOT NULL DEFAULT 'Income'",
      );
    }

    if (!columnNames.contains('updated_at')) {
      await db.execute("ALTER TABLE income ADD COLUMN updated_at TEXT");
    }

    if (!columnNames.contains('shift_id')) {
      await db.execute(
        "ALTER TABLE income ADD COLUMN shift_id TEXT NOT NULL DEFAULT ''",
      );
    }

    if (!columnNames.contains('amount')) {
      await db.execute(
        "ALTER TABLE income ADD COLUMN amount REAL NOT NULL DEFAULT 0",
      );
    }

    if (!columnNames.contains('tip')) {
      await db.execute(
        "ALTER TABLE income ADD COLUMN tip REAL NOT NULL DEFAULT 0",
      );
    }

    if (!columnNames.contains('note')) {
      await db.execute("ALTER TABLE income ADD COLUMN note TEXT");
    }

    if (!columnNames.contains('created_at')) {
      await db.execute(
        "ALTER TABLE income ADD COLUMN created_at TEXT NOT NULL DEFAULT ''",
      );
    }
  }

  static Future<void> _migrateExpenseTable(Database db) async {
    final tableExists = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='expense'",
    );

    if (tableExists.isEmpty) {
      await db.execute("""
CREATE TABLE IF NOT EXISTS expense(
id TEXT PRIMARY KEY,
shift_id TEXT NOT NULL,
title TEXT NOT NULL,
amount REAL NOT NULL,
note TEXT,
created_at TEXT NOT NULL,
updated_at TEXT
)
""");
      return;
    }

    final columns = await db.rawQuery("PRAGMA table_info(expense)");
    final columnNames = columns.map((column) => column['name']).toSet();

    if (!columnNames.contains('shift_id')) {
      await db.execute(
        "ALTER TABLE expense ADD COLUMN shift_id TEXT NOT NULL DEFAULT ''",
      );
    }

    if (!columnNames.contains('title')) {
      await db.execute(
        "ALTER TABLE expense ADD COLUMN title TEXT NOT NULL DEFAULT 'Expense'",
      );
    }

    if (!columnNames.contains('amount')) {
      await db.execute(
        "ALTER TABLE expense ADD COLUMN amount REAL NOT NULL DEFAULT 0",
      );
    }

    if (!columnNames.contains('note')) {
      await db.execute("ALTER TABLE expense ADD COLUMN note TEXT");
    }

    if (!columnNames.contains('created_at')) {
      await db.execute(
        "ALTER TABLE expense ADD COLUMN created_at TEXT NOT NULL DEFAULT ''",
      );
    }

    if (!columnNames.contains('updated_at')) {
      await db.execute("ALTER TABLE expense ADD COLUMN updated_at TEXT");
    }
  }
}
