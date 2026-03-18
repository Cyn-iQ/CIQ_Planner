import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../models/app_settings.dart';

class SettingsRepository {
  SettingsRepository._();

  static const AppSettings _defaultSettings = AppSettings(
    dayStartTime: '00:00',
    shortTaskBaseCapacity: 3,
    fixedTaskBaseCapacity: 5,
    shortTaskCurrentCapacity: 3,
    fixedTaskCurrentCapacity: 5,
  );

  static Future<AppSettings> getSettings() async {
    final db = await AppDatabase.database;

    final maps = await db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: ['app_settings'],
      limit: 1,
    );

    if (maps.isEmpty) {
      await saveSettings(_defaultSettings);
      return _defaultSettings;
    }

    return AppSettings.fromMap(maps.first);
  }

  static Future<void> saveSettings(AppSettings settings) async {
    final db = await AppDatabase.database;

    await db.insert(
      'app_settings',
      settings.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}