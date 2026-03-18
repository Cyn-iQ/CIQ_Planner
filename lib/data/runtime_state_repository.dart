import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';

class RuntimeStateRepository {
  RuntimeStateRepository._();

  static Future<String?> getValue(String key) async {
    final db = await AppDatabase.database;

    final maps = await db.query(
      'app_runtime_state',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return maps.first['value'] as String;
  }

  static Future<void> setValue({
    required String key,
    required String value,
  }) async {
    final db = await AppDatabase.database;

    await db.insert(
      'app_runtime_state',
      {
        'key': key,
        'value': value,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<String?> getLastRolloverLogicDay() async {
    return getValue('last_rollover_logic_day');
  }

  static Future<void> setLastRolloverLogicDay(String logicDay) async {
    await setValue(
      key: 'last_rollover_logic_day',
      value: logicDay,
    );
  }

  static Future<String?> getCurrentDailyTaskLogicDay() async {
    return getValue('current_daily_task_logic_day');
  }

  static Future<void> setCurrentDailyTaskLogicDay(String logicDay) async {
    await setValue(
      key: 'current_daily_task_logic_day',
      value: logicDay,
    );
  }
}