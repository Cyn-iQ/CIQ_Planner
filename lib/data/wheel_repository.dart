import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';

class WheelRepository {
  WheelRepository._();

  static Future<void> addSequence({
    required String logicDate,
    required String type, // daily
    required String targetId,
    bool allowDuplicate = false,
  }) async {
    final db = await AppDatabase.database;

    if (!allowDuplicate) {
      final exists = await db.query(
        'wheel_sequences',
        where: 'logic_date = ? AND type = ? AND target_id = ?',
        whereArgs: [logicDate, type, targetId],
        limit: 1,
      );

      if (exists.isNotEmpty) return;
    }

    await db.insert(
      'wheel_sequences',
      {
        'id': '${DateTime.now().microsecondsSinceEpoch}_$targetId',
        'logic_date': logicDate,
        'type': type,
        'target_id': targetId,
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<String>> getSequence({
    required String logicDate,
    required String type,
  }) async {
    final db = await AppDatabase.database;

    final maps = await db.query(
      'wheel_sequences',
      where: 'logic_date = ? AND type = ?',
      whereArgs: [logicDate, type],
      orderBy: 'created_at ASC',
    );

    return maps.map((e) => e['target_id'] as String).toList();
  }

  static Future<bool> containsItem({
    required String logicDate,
    required String type,
    required String targetId,
  }) async {
    final db = await AppDatabase.database;

    final maps = await db.query(
      'wheel_sequences',
      where: 'logic_date = ? AND type = ? AND target_id = ?',
      whereArgs: [logicDate, type, targetId],
      limit: 1,
    );

    return maps.isNotEmpty;
  }

  static Future<void> removeItem({
    required String logicDate,
    required String targetId,
  }) async {
    final db = await AppDatabase.database;

    await db.delete(
      'wheel_sequences',
      where: 'logic_date = ? AND target_id = ?',
      whereArgs: [logicDate, targetId],
    );
  }

  static Future<void> clearByDate(String logicDate) async {
    final db = await AppDatabase.database;

    await db.delete(
      'wheel_sequences',
      where: 'logic_date = ?',
      whereArgs: [logicDate],
    );
  }
}
