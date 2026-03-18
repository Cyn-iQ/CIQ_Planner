import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';

class BackupFileException implements Exception {
  final String message;

  const BackupFileException(this.message);

  @override
  String toString() => message;
}

class BackupCompatibilityException implements Exception {
  final String message;

  const BackupCompatibilityException(this.message);

  @override
  String toString() => message;
}

class BackupImportResult {
  final int sourceSchemaVersion;
  final int appSchemaVersion;

  const BackupImportResult({
    required this.sourceSchemaVersion,
    required this.appSchemaVersion,
  });
}

class DataBackupService {
  DataBackupService._();

  static const String _backupFilePrefix = 'planbook_backup';
  static const String _backupFileSuffix = '.db';

  static Future<File> exportBackup() async {
    final db = await AppDatabase.database;

    final tempDir = await getTemporaryDirectory();
    final backupDir = Directory(join(tempDir.path, 'planbook_backups'));
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }

    final timestamp = _formatTimestamp(DateTime.now());
    final backupPath = join(
      backupDir.path,
      '${_backupFilePrefix}_$timestamp$_backupFileSuffix',
    );

    await _deleteIfExists(backupPath);

    final escapedPath = backupPath.replaceAll("'", "''");
    await db.execute("VACUUM INTO '$escapedPath'");

    return File(backupPath);
  }

  static Future<BackupImportResult> importBackup(String sourcePath) async {
    final normalizedPath = sourcePath.trim();
    if (normalizedPath.isEmpty) {
      throw const BackupFileException('备份文件路径为空。');
    }

    final sourceFile = File(normalizedPath);
    if (!await sourceFile.exists()) {
      throw const BackupFileException('备份文件不存在。');
    }
    if (await sourceFile.length() <= 0) {
      throw const BackupFileException('备份文件为空。');
    }

    final sourceSchemaVersion = await _readSchemaVersion(normalizedPath);
    if (sourceSchemaVersion < 1) {
      throw BackupCompatibilityException(
        '不支持的备份版本：$sourceSchemaVersion',
      );
    }

    if (sourceSchemaVersion > AppDatabase.schemaVersion) {
      throw BackupCompatibilityException(
        '备份版本 $sourceSchemaVersion 高于当前应用支持版本 ${AppDatabase.schemaVersion}。',
      );
    }

    await AppDatabase.closeDatabase();

    final targetPath = await AppDatabase.getDatabaseFilePath();
    final guardPath = '$targetPath.pre_import_guard';
    final targetFile = File(targetPath);
    final guardFile = File(guardPath);

    if (await targetFile.exists()) {
      await _deleteIfExists(guardPath);
      await targetFile.copy(guardPath);
    }

    try {
      await _deleteIfExists(targetPath);
      await _deleteIfExists('$targetPath-wal');
      await _deleteIfExists('$targetPath-shm');
      await sourceFile.copy(targetPath);
      await AppDatabase.database;
    } catch (e) {
      if (await guardFile.exists()) {
        await _deleteIfExists(targetPath);
        await guardFile.copy(targetPath);
        await AppDatabase.database;
      }
      rethrow;
    } finally {
      await _deleteIfExists(guardPath);
    }

    return BackupImportResult(
      sourceSchemaVersion: sourceSchemaVersion,
      appSchemaVersion: AppDatabase.schemaVersion,
    );
  }

  static Future<void> clearAllData() async {
    await AppDatabase.closeDatabase();

    final targetPath = await AppDatabase.getDatabaseFilePath();
    await _deleteIfExists(targetPath);
    await _deleteIfExists('$targetPath-wal');
    await _deleteIfExists('$targetPath-shm');

    // Recreate database and default rows.
    await AppDatabase.database;
  }

  static Future<int> _readSchemaVersion(String path) async {
    Database? db;

    try {
      db = await openDatabase(
        path,
        readOnly: true,
        singleInstance: false,
      );

      final rows = await db.rawQuery('PRAGMA user_version;');
      if (rows.isEmpty) {
        throw const BackupFileException('无法读取备份版本信息。');
      }

      final rawVersion = rows.first['user_version'];
      if (rawVersion is int) return rawVersion;
      return int.tryParse(rawVersion.toString()) ?? 0;
    } on DatabaseException {
      throw const BackupFileException('所选文件不是有效的 SQLite 备份。');
    } finally {
      await db?.close();
    }
  }

  static Future<void> _deleteIfExists(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  static String _formatTimestamp(DateTime dateTime) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${dateTime.year}${two(dateTime.month)}${two(dateTime.day)}_${two(dateTime.hour)}${two(dateTime.minute)}${two(dateTime.second)}';
  }
}
