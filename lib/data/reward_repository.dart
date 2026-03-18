import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../models/reward_item.dart';

class RewardRepository {
  RewardRepository._();

  static Future<List<RewardItem>> getItems() async {
    final db = await AppDatabase.database;

    final maps = await db.query(
      'reward_items',
      orderBy: 'created_at DESC',
    );

    return maps.map(RewardItem.fromMap).toList();
  }

  static Future<void> addItem(RewardItem item) async {
    final db = await AppDatabase.database;

    await db.insert(
      'reward_items',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> updateItem(RewardItem item) async {
    final db = await AppDatabase.database;

    await db.update(
      'reward_items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  static Future<void> deleteItem(String id) async {
    final db = await AppDatabase.database;

    await db.delete(
      'reward_items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}