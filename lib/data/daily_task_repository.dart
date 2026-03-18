import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../models/fixed_plan_template.dart';
import '../models/task.dart';

class DailyTaskRepository {
  DailyTaskRepository._();

  static Future<List<Task>> getTasksByLogicDate(String logicDate) async {
    final db = await AppDatabase.database;
    final maps = await db.query(
      'daily_tasks',
      where: 'logic_date = ?',
      whereArgs: [logicDate],
      orderBy: 'created_at DESC',
    );

    return maps.map(Task.fromMap).toList();
  }

  static Future<List<String>> getAllLogicDates() async {
    final db = await AppDatabase.database;
    final maps = await db.rawQuery('''
      SELECT DISTINCT logic_date
      FROM daily_tasks
      ORDER BY logic_date DESC
    ''');

    return maps
        .map((map) => map['logic_date'] as String)
        .where((date) => date.isNotEmpty)
        .toList();
  }

  static Future<void> addTask(Task task) async {
    final db = await AppDatabase.database;
    await db.insert(
      'daily_tasks',
      task.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> removeTask(String id) async {
    final db = await AppDatabase.database;
    await db.delete(
      'daily_tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> updateTask(Task updatedTask) async {
    final db = await AppDatabase.database;
    await db.update(
      'daily_tasks',
      updatedTask.toMap(),
      where: 'id = ?',
      whereArgs: [updatedTask.id],
    );
  }

  static Future<void> deleteTasksByLogicDate(String logicDate) async {
    final db = await AppDatabase.database;
    await db.delete(
      'daily_tasks',
      where: 'logic_date = ?',
      whereArgs: [logicDate],
    );
  }

  static Future<void> insertDefaultDailyTasksForLogicDate(
    String logicDate,
  ) async {
    final db = await AppDatabase.database;

    // Legacy cleanup for old demo task rows.
    await db.delete(
      'daily_tasks',
      where: 'type = ? AND id LIKE ?',
      whereArgs: [TaskType.daily.name, 'daily_%_1'],
    );
  }

  static Future<void> ensureFixedTasksForLogicDate({
    required String logicDate,
    required List<FixedPlanTemplate> templates,
    required int fixedCapacity,
  }) async {
    final db = await AppDatabase.database;
    final limitedTemplates = templates.take(fixedCapacity).toList();

    for (final template in limitedTemplates) {
      final fixedTaskId = 'fixed_${logicDate}_${template.id}';

      final existing = await db.query(
        'daily_tasks',
        where: 'id = ?',
        whereArgs: [fixedTaskId],
        limit: 1,
      );

      if (existing.isNotEmpty) continue;

      final task = Task(
        id: fixedTaskId,
        title: template.title,
        description: template.description,
        type: TaskType.fixed,
        status: TaskStatus.pending,
        points: template.points,
        progress: 0,
        targetCount: 1,
        createdAt: DateTime.now(),
        logicDate: logicDate,
      );

      await db.insert(
        'daily_tasks',
        task.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  static Future<int> getTaskCountByTypeAndLogicDate({
    required String logicDate,
    required TaskType type,
  }) async {
    final db = await AppDatabase.database;
    final maps = await db.query(
      'daily_tasks',
      where: 'logic_date = ? AND type = ?',
      whereArgs: [logicDate, type.name],
    );

    return maps.length;
  }

  static Future<Map<String, int>> getTaskStatsByTypeAndLogicDate({
    required String logicDate,
    required TaskType type,
  }) async {
    final db = await AppDatabase.database;
    final maps = await db.query(
      'daily_tasks',
      where: 'logic_date = ? AND type = ?',
      whereArgs: [logicDate, type.name],
    );

    final totalCount = maps.length;
    final completedCount = maps
        .where((map) => map['status'] == TaskStatus.completed.name)
        .length;

    return {
      'totalCount': totalCount,
      'completedCount': completedCount,
    };
  }

  static Future<int> getCompletedPointsByLogicDate(String logicDate) async {
    final db = await AppDatabase.database;
    final maps = await db.query(
      'daily_tasks',
      where: 'logic_date = ? AND status = ?',
      whereArgs: [logicDate, TaskStatus.completed.name],
    );

    int total = 0;
    for (final map in maps) {
      total += map['points'] as int;
    }
    return total;
  }
}
