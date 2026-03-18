import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../models/fixed_plan_template.dart';

class FixedPlanTemplateRepository {
  FixedPlanTemplateRepository._();

  static Future<List<FixedPlanTemplate>> getTemplates() async {
    final db = await AppDatabase.database;
    final maps = await db.query(
      'fixed_plan_templates',
      orderBy: 'created_at DESC',
    );

    return maps.map(FixedPlanTemplate.fromMap).toList();
  }

  static Future<int> getTemplateCount() async {
    final db = await AppDatabase.database;
    final maps = await db.query('fixed_plan_templates');
    return maps.length;
  }

  static Future<List<FixedPlanTemplate>> getTemplatesLimited(int limit) async {
    final db = await AppDatabase.database;
    final maps = await db.query(
      'fixed_plan_templates',
      orderBy: 'created_at DESC',
      limit: limit,
    );

    return maps.map(FixedPlanTemplate.fromMap).toList();
  }

  static Future<void> addTemplate(FixedPlanTemplate template) async {
    final db = await AppDatabase.database;
    await db.insert(
      'fixed_plan_templates',
      template.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> updateTemplate(FixedPlanTemplate template) async {
    final db = await AppDatabase.database;
    await db.update(
      'fixed_plan_templates',
      template.toMap(),
      where: 'id = ?',
      whereArgs: [template.id],
    );
  }

  static Future<void> removeTemplate(String id) async {
    final db = await AppDatabase.database;
    await db.delete(
      'fixed_plan_templates',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}