import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../models/daily_settlement.dart';

class DailySettlementRepository {
  DailySettlementRepository._();

  static Future<bool> hasSettled(String logicDate) async {
    final db = await AppDatabase.database;

    final maps = await db.query(
      'daily_settlements',
      where: 'logic_date = ?',
      whereArgs: [logicDate],
      limit: 1,
    );

    return maps.isNotEmpty;
  }

  static Future<void> insertSettlement(DailySettlement settlement) async {
    final db = await AppDatabase.database;

    await db.insert(
      'daily_settlements',
      settlement.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<DailySettlement>> getSettlements() async {
    final db = await AppDatabase.database;

    final maps = await db.query(
      'daily_settlements',
      orderBy: 'logic_date DESC',
    );

    return maps.map(DailySettlement.fromMap).toList();
  }
}