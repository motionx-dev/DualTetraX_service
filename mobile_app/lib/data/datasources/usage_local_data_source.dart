import 'package:sqflite/sqflite.dart';
import '../models/usage_session_model.dart';
import 'database_helper.dart';

abstract class UsageLocalDataSource {
  Future<void> insertSession(UsageSessionModel session);
  Future<void> updateSession(UsageSessionModel session);
  Future<UsageSessionModel?> getActiveSession();
  Future<List<UsageSessionModel>> getSessionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  );
  Future<List<UsageSessionModel>> getSessionsByDate(DateTime date);
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
      where: 'id = ?',
      whereArgs: [session.id],
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
  Future<void> deleteAllSessions() async {
    final db = await databaseHelper.database;
    await db.delete('usage_sessions');
  }

  @override
  Future<void> deleteSessionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await databaseHelper.database;
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
