import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../models/app_settings.dart';

class SettingsRepository {
  SettingsRepository._();

  static const int maxShortTaskCapacity = AppSettings.maxShortTaskCapacity;
  static const int maxFixedTaskCapacity = AppSettings.maxFixedTaskCapacity;

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

    final loaded = AppSettings.fromMap(maps.first);
    final normalized = _normalizeSettings(loaded);

    if (!_isSame(loaded, normalized)) {
      await saveSettings(normalized);
    }

    return normalized;
  }

  static Future<void> saveSettings(AppSettings settings) async {
    final db = await AppDatabase.database;
    final normalized = _normalizeSettings(settings);

    await db.insert(
      'app_settings',
      normalized.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static AppSettings _normalizeSettings(AppSettings settings) {
    final shortBase = settings.shortTaskBaseCapacity
        .clamp(1, maxShortTaskCapacity)
        .toInt();
    final fixedBase = settings.fixedTaskBaseCapacity
        .clamp(1, maxFixedTaskCapacity)
        .toInt();

    final shortCurrent = settings.shortTaskCurrentCapacity
        .clamp(shortBase, maxShortTaskCapacity)
        .toInt();
    final fixedCurrent = settings.fixedTaskCurrentCapacity
        .clamp(fixedBase, maxFixedTaskCapacity)
        .toInt();

    return settings.copyWith(
      shortTaskBaseCapacity: shortBase,
      fixedTaskBaseCapacity: fixedBase,
      shortTaskCurrentCapacity: shortCurrent,
      fixedTaskCurrentCapacity: fixedCurrent,
    );
  }

  static bool _isSame(AppSettings a, AppSettings b) {
    return a.dayStartTime == b.dayStartTime &&
        a.shortTaskBaseCapacity == b.shortTaskBaseCapacity &&
        a.fixedTaskBaseCapacity == b.fixedTaskBaseCapacity &&
        a.shortTaskCurrentCapacity == b.shortTaskCurrentCapacity &&
        a.fixedTaskCurrentCapacity == b.fixedTaskCurrentCapacity;
  }
}
