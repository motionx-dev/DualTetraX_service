import 'package:sqflite/sqflite.dart';
import '../models/usage_session_model.dart';
import '../../domain/entities/sync_status.dart';
import '../../domain/entities/battery_sample.dart';
import 'database_helper.dart';

abstract class UsageLocalDataSource {
  Future<void> insertSession(UsageSessionModel session);
  Future<void> updateSession(UsageSessionModel session);
  Future<UsageSessionModel?> getActiveSession();
  Future<UsageSessionModel?> getSessionByUuid(String uuid);
  Future<List<UsageSessionModel>> getSessionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  );
  Future<List<UsageSessionModel>> getSessionsByDate(DateTime date);
  Future<List<UsageSessionModel>> getSessionsBySyncStatus(SyncStatus status);
  Future<List<UsageSessionModel>> getUnsyncedSessions();
  Future<void> updateSyncStatus(String uuid, SyncStatus status);
  Future<void> insertBatterySamples(String sessionUuid, List<BatterySample> samples);
  Future<List<BatterySampleModel>> getBatterySamples(String sessionUuid);
  Future<void> deleteAllSessions();
  Future<void> deleteSessionsByDateRange(DateTime startDate, DateTime endDate);
}

class UsageLocalDataSourceImpl implements UsageLocalDataSource {
  final DatabaseHelper databaseHelper;

  UsageLocalDataSourceImpl(this.databaseHelper);

  @override
  Future<void> insertSession(UsageSessionModel session) async {
    final db = await databaseHelper.database;
    await db.insert(
      'usage_sessions',
      session.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> updateSession(UsageSessionModel session) async {
    final db = await databaseHelper.database;
    await db.update(
      'usage_sessions',
      session.toMap(),
      where: 'uuid = ?',
      whereArgs: [session.uuid],
    );
  }

  @override
  Future<UsageSessionModel?> getActiveSession() async {
    final db = await databaseHelper.database;
    final results = await db.query(
      'usage_sessions',
      where: 'end_time IS NULL',
      limit: 1,
    );

    if (results.isEmpty) return null;
    return UsageSessionModel.fromMap(results.first);
  }

  @override
  Future<UsageSessionModel?> getSessionByUuid(String uuid) async {
    final db = await databaseHelper.database;
    final results = await db.query(
      'usage_sessions',
      where: 'uuid = ?',
      whereArgs: [uuid],
      limit: 1,
    );

    if (results.isEmpty) return null;
    final session = UsageSessionModel.fromMap(results.first);
    final samples = await getBatterySamples(uuid);
    return session.copyWith(batterySamples: samples) as UsageSessionModel;
  }

  @override
  Future<List<UsageSessionModel>> getSessionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await databaseHelper.database;
    final results = await db.query(
      'usage_sessions',
      where: 'start_time >= ? AND start_time <= ?',
      whereArgs: [
        startDate.millisecondsSinceEpoch,
        endDate.millisecondsSinceEpoch,
      ],
      orderBy: 'start_time DESC',
    );

    return results.map((map) => UsageSessionModel.fromMap(map)).toList();
  }

  @override
  Future<List<UsageSessionModel>> getSessionsByDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return getSessionsByDateRange(startOfDay, endOfDay);
  }

  @override
  Future<List<UsageSessionModel>> getSessionsBySyncStatus(SyncStatus status) async {
    final db = await databaseHelper.database;
    final results = await db.query(
      'usage_sessions',
      where: 'sync_status = ?',
      whereArgs: [status.value],
      orderBy: 'start_time DESC',
    );

    return results.map((map) => UsageSessionModel.fromMap(map)).toList();
  }

  @override
  Future<List<UsageSessionModel>> getUnsyncedSessions() async {
    final db = await databaseHelper.database;
    final results = await db.query(
      'usage_sessions',
      where: 'sync_status < ?',
      whereArgs: [SyncStatus.fullySynced.value],
      orderBy: 'start_time ASC',
    );

    return results.map((map) => UsageSessionModel.fromMap(map)).toList();
  }

  @override
  Future<void> updateSyncStatus(String uuid, SyncStatus status) async {
    final db = await databaseHelper.database;
    await db.update(
      'usage_sessions',
      {
        'sync_status': status.value,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'uuid = ?',
      whereArgs: [uuid],
    );
  }

  @override
  Future<void> insertBatterySamples(String sessionUuid, List<BatterySample> samples) async {
    final db = await databaseHelper.database;
    final batch = db.batch();
    for (final sample in samples) {
      batch.insert(
        'battery_samples',
        BatterySampleModel.fromEntity(sample).toMap(sessionUuid),
      );
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<List<BatterySampleModel>> getBatterySamples(String sessionUuid) async {
    final db = await databaseHelper.database;
    final results = await db.query(
      'battery_samples',
      where: 'session_uuid = ?',
      whereArgs: [sessionUuid],
      orderBy: 'elapsed_seconds ASC',
    );

    return results.map((map) => BatterySampleModel.fromMap(map)).toList();
  }

  @override
  Future<void> deleteAllSessions() async {
    final db = await databaseHelper.database;
    await db.delete('battery_samples');
    await db.delete('usage_sessions');
  }

  @override
  Future<void> deleteSessionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await databaseHelper.database;
    final sessions = await getSessionsByDateRange(startDate, endDate);
    for (final session in sessions) {
      await db.delete(
        'battery_samples',
        where: 'session_uuid = ?',
        whereArgs: [session.uuid],
      );
    }
    await db.delete(
      'usage_sessions',
      where: 'start_time >= ? AND start_time <= ?',
      whereArgs: [
        startDate.millisecondsSinceEpoch,
        endDate.millisecondsSinceEpoch,
      ],
    );
  }
}
