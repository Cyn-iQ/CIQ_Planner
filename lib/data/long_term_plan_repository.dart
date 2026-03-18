import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../models/long_term_plan.dart';
import '../models/long_term_plan_history.dart';
import '../models/long_term_stats.dart';

class LongTermPlanRepository {
  LongTermPlanRepository._();

  static Future<List<LongTermPlan>> getPlans() async {
    final db = await AppDatabase.database;

    await _removeLegacyDefaultPlans(db);

    final maps = await db.query(
      'long_term_plans',
      orderBy: 'created_at DESC',
    );

    return maps.map(LongTermPlan.fromMap).toList();
  }

  static Future<List<LongTermPlanHistory>> getHistoryPlans() async {
    final db = await AppDatabase.database;
    final maps = await db.query(
      'long_term_plan_history',
      orderBy: 'finished_at DESC',
    );

    return maps.map(LongTermPlanHistory.fromMap).toList();
  }

  static Future<LongTermStats> getStats() async {
    final activePlans = await getPlans();
    final historyPlans = await getHistoryPlans();

    final activeCount = activePlans.length;
    final historyCount = historyPlans.length;

    final completedCount = historyPlans
        .where((plan) => plan.status == LongTermPlanStatus.completed)
        .length;

    final pressLineDoneCount = historyPlans
        .where((plan) => plan.status == LongTermPlanStatus.pressLineDone)
        .length;

    final expiredCount = historyPlans
        .where((plan) => plan.status == LongTermPlanStatus.expired)
        .length;

    final totalProgressActive = activePlans.fold<int>(
      0,
      (sum, plan) => sum + plan.progressCount,
    );

    final totalProgressHistory = historyPlans.fold<int>(
      0,
      (sum, plan) => sum + plan.progressCount,
    );

    final totalProgressCount = totalProgressActive + totalProgressHistory;

    final totalPlanCount = activeCount + historyCount;

    final double averageProgressCount =
        totalPlanCount == 0 ? 0.0 : totalProgressCount / totalPlanCount;

    final double completionRate = totalPlanCount == 0
        ? 0.0
        : (completedCount + pressLineDoneCount) / totalPlanCount;

    return LongTermStats(
      activeCount: activeCount,
      historyCount: historyCount,
      completedCount: completedCount,
      pressLineDoneCount: pressLineDoneCount,
      expiredCount: expiredCount,
      totalProgressCount: totalProgressCount,
      averageProgressCount: averageProgressCount,
      completionRate: completionRate,
    );
  }

  static Future<void> addPlan(LongTermPlan plan) async {
    final db = await AppDatabase.database;
    await db.insert(
      'long_term_plans',
      plan.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> removePlan(String id) async {
    final db = await AppDatabase.database;
    await db.delete(
      'long_term_plans',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> updatePlan(LongTermPlan updatedPlan) async {
    final db = await AppDatabase.database;
    await db.update(
      'long_term_plans',
      updatedPlan.toMap(),
      where: 'id = ?',
      whereArgs: [updatedPlan.id],
    );
  }

  static Future<void> moveToHistory(
    LongTermPlan plan,
    LongTermPlanStatus status,
  ) async {
    final db = await AppDatabase.database;

    final history = LongTermPlanHistory.fromPlan(
      plan,
      DateTime.now(),
      status,
    );

    await db.insert(
      'long_term_plan_history',
      history.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    await db.delete(
      'long_term_plans',
      where: 'id = ?',
      whereArgs: [plan.id],
    );
  }

  static Future<void> checkAndExpirePlans() async {
    final db = await AppDatabase.database;

    await _removeLegacyDefaultPlans(db);

    final maps = await db.query('long_term_plans');

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (final map in maps) {
      final plan = LongTermPlan.fromMap(map);

      final deadline = DateTime(
        plan.deadline.year,
        plan.deadline.month,
        plan.deadline.day,
      );

      if (deadline.isBefore(today)) {
        await moveToHistory(plan, LongTermPlanStatus.pressLineDone);
      }
    }
  }

  static Future<void> _removeLegacyDefaultPlans(Database db) async {
    await db.delete(
      'long_term_plans',
      where: 'id IN (?, ?)',
      whereArgs: ['p1', 'p2'],
    );
  }
}
