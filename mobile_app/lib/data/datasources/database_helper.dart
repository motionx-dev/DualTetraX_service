import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';

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
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE usage_sessions (
        uuid TEXT PRIMARY KEY,
        start_time INTEGER NOT NULL,
        end_time INTEGER,
        shot_type INTEGER NOT NULL,
        mode INTEGER NOT NULL,
        level INTEGER NOT NULL,
        led_pattern INTEGER,
        working_duration_seconds INTEGER DEFAULT 0,
        pause_duration_seconds INTEGER DEFAULT 0,
        pause_count INTEGER DEFAULT 0,
        termination_reason INTEGER,
        completion_percent INTEGER DEFAULT 0,
        had_temperature_warning INTEGER DEFAULT 0,
        had_battery_warning INTEGER DEFAULT 0,
        start_battery_level INTEGER NOT NULL,
        end_battery_level INTEGER,
        sync_status INTEGER DEFAULT 0,
        time_synced INTEGER DEFAULT 1,
        device_id TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE battery_samples (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_uuid TEXT NOT NULL,
        elapsed_seconds INTEGER NOT NULL,
        voltage_mv INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (session_uuid) REFERENCES usage_sessions(uuid)
          ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_uuid TEXT NOT NULL,
        action TEXT NOT NULL,
        payload TEXT,
        retry_count INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL,
        last_attempt_at INTEGER,
        FOREIGN KEY (session_uuid) REFERENCES usage_sessions(uuid)
          ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE sync_metadata (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    await db.execute('CREATE INDEX idx_sessions_start_time ON usage_sessions(start_time)');
    await db.execute('CREATE INDEX idx_sessions_end_time ON usage_sessions(end_time)');
    await db.execute('CREATE INDEX idx_sessions_shot_type ON usage_sessions(shot_type)');
    await db.execute('CREATE INDEX idx_sessions_sync_status ON usage_sessions(sync_status)');
    await db.execute('CREATE INDEX idx_sessions_device_id ON usage_sessions(device_id)');
    await db.execute('CREATE INDEX idx_battery_session ON battery_samples(session_uuid)');
    await db.execute('CREATE INDEX idx_battery_elapsed ON battery_samples(elapsed_seconds)');
    await db.execute('CREATE INDEX idx_sync_queue_action ON sync_queue(action)');
    await db.execute('CREATE INDEX idx_sync_queue_created ON sync_queue(created_at)');

    final now = DateTime.now().millisecondsSinceEpoch;
    await db.insert('sync_metadata', {
      'key': 'last_device_sync_timestamp',
      'value': '0',
      'updated_at': now,
    });
    await db.insert('sync_metadata', {
      'key': 'last_server_sync_timestamp',
      'value': '0',
      'updated_at': now,
    });
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _migrateToV2(db);
    }
    if (oldVersion < 3) {
      await _migrateToV3(db);
    }
  }

  Future<void> _migrateToV3(Database db) async {
    // Add time_synced column (1 = timestamps are real time, 0 = device uptime)
    // Default to 1 for existing sessions (assume they were created with app connected)
    await db.execute('ALTER TABLE usage_sessions ADD COLUMN time_synced INTEGER DEFAULT 1');
  }

  Future<void> _migrateToV2(Database db) async {
    await db.execute('ALTER TABLE usage_sessions ADD COLUMN uuid TEXT');
    await db.execute('ALTER TABLE usage_sessions ADD COLUMN led_pattern INTEGER');
    await db.execute('ALTER TABLE usage_sessions ADD COLUMN pause_count INTEGER DEFAULT 0');
    await db.execute('ALTER TABLE usage_sessions ADD COLUMN termination_reason INTEGER');
    await db.execute('ALTER TABLE usage_sessions ADD COLUMN completion_percent INTEGER DEFAULT 0');
    await db.execute('ALTER TABLE usage_sessions ADD COLUMN sync_status INTEGER DEFAULT 0');
    await db.execute('ALTER TABLE usage_sessions ADD COLUMN device_id TEXT');
    await db.execute('ALTER TABLE usage_sessions ADD COLUMN created_at INTEGER');
    await db.execute('ALTER TABLE usage_sessions ADD COLUMN updated_at INTEGER');

    final sessions = await db.query('usage_sessions');
    final uuid = const Uuid();
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final session in sessions) {
      final newUuid = uuid.v4();
      await db.update(
        'usage_sessions',
        {
          'uuid': newUuid,
          'created_at': session['start_time'] ?? now,
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [session['id']],
      );
    }

    await db.execute('''
      CREATE TABLE battery_samples (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_uuid TEXT NOT NULL,
        elapsed_seconds INTEGER NOT NULL,
        voltage_mv INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (session_uuid) REFERENCES usage_sessions(uuid)
          ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_uuid TEXT NOT NULL,
        action TEXT NOT NULL,
        payload TEXT,
        retry_count INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL,
        last_attempt_at INTEGER,
        FOREIGN KEY (session_uuid) REFERENCES usage_sessions(uuid)
          ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE sync_metadata (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    await db.execute('CREATE INDEX idx_sessions_sync_status ON usage_sessions(sync_status)');
    await db.execute('CREATE INDEX idx_sessions_device_id ON usage_sessions(device_id)');
    await db.execute('CREATE INDEX idx_battery_session ON battery_samples(session_uuid)');
    await db.execute('CREATE INDEX idx_battery_elapsed ON battery_samples(elapsed_seconds)');
    await db.execute('CREATE INDEX idx_sync_queue_action ON sync_queue(action)');
    await db.execute('CREATE INDEX idx_sync_queue_created ON sync_queue(created_at)');

    final now2 = DateTime.now().millisecondsSinceEpoch;
    await db.insert('sync_metadata', {
      'key': 'last_device_sync_timestamp',
      'value': '0',
      'updated_at': now2,
    });
    await db.insert('sync_metadata', {
      'key': 'last_server_sync_timestamp',
      'value': '0',
      'updated_at': now2,
    });
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
