import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'dualtetrax.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Usage Sessions Table
    await db.execute('''
      CREATE TABLE usage_sessions (
        id TEXT PRIMARY KEY,
        start_time INTEGER NOT NULL,
        end_time INTEGER,
        shot_type INTEGER NOT NULL,
        mode INTEGER NOT NULL,
        level INTEGER NOT NULL,
        working_duration_seconds INTEGER DEFAULT 0,
        pause_duration_seconds INTEGER DEFAULT 0,
        had_temperature_warning INTEGER DEFAULT 0,
        had_battery_warning INTEGER DEFAULT 0,
        start_battery_level INTEGER NOT NULL,
        end_battery_level INTEGER
      )
    ''');

    // Indexes for faster queries
    await db.execute('''
      CREATE INDEX idx_sessions_start_time
      ON usage_sessions(start_time)
    ''');

    await db.execute('''
      CREATE INDEX idx_sessions_end_time
      ON usage_sessions(end_time)
    ''');

    await db.execute('''
      CREATE INDEX idx_sessions_shot_type
      ON usage_sessions(shot_type)
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database schema upgrades here
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
