import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../models/point_record.dart';
import '../models/score_summary.dart';

class ScoreRepository {
  ScoreRepository._();

  static Future<void> addEarnRecord({
    required int score,
    required String source,
    required String remark,
  }) async {
    final db = await AppDatabase.database;

    final record = PointRecord(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      delta: score,
      type: PointRecordType.earn,
      source: source,
      remark: remark,
      createdAt: DateTime.now(),
    );

    await db.insert(
      'point_records',
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> addSpendRecord({
    required int score,
    required String source,
    required String remark,
  }) async {
    final db = await AppDatabase.database;
    final summary = await getSummary();

    final actualSpend = summary.currentScore >= score
        ? score
        : summary.currentScore;

    final record = PointRecord(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      delta: -actualSpend,
      type: PointRecordType.spend,
      source: source,
      remark: remark,
      createdAt: DateTime.now(),
    );

    await db.insert(
      'point_records',
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<bool> redeemReward({
    required int cost,
    required String rewardTitle,
  }) async {
    final summary = await getSummary();

    if (summary.currentScore < cost) {
      return false;
    }

    await addSpendRecord(
      score: cost,
      source: 'reward_shop',
      remark: '兑换奖励：$rewardTitle',
    );

    return true;
  }

  static Future<void> addSystemBonusRecord({
    required int score,
    required String remark,
  }) async {
    final db = await AppDatabase.database;

    final record = PointRecord(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      delta: score,
      type: PointRecordType.earn,
      source: 'daily_settlement_bonus',
      remark: remark,
      createdAt: DateTime.now(),
    );

    await db.insert(
      'point_records',
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<ScoreSummary> getSummary() async {
    final db = await AppDatabase.database;
    final maps = await db.query('point_records');

    int currentScore = 0;
    int totalEarned = 0;
    int totalSpent = 0;

    for (final map in maps) {
      final delta = map['delta'] as int;

      if (delta > 0) {
        totalEarned += delta;
      } else {
        totalSpent += (-delta);
      }

      currentScore += delta;
    }

    if (currentScore < 0) {
      currentScore = 0;
    }

    return ScoreSummary(
      currentScore: currentScore,
      totalEarned: totalEarned,
      totalSpent: totalSpent,
    );
  }

  static Future<List<PointRecord>> getRecords() async {
    final db = await AppDatabase.database;
    final maps = await db.query(
      'point_records',
      orderBy: 'created_at DESC',
    );

    return maps.map(PointRecord.fromMap).toList();
  }
}