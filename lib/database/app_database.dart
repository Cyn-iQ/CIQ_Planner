import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static const String dbFileName = 'planbook.db';
  static const int schemaVersion = 12;

  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final path = await getDatabaseFilePath();

    return openDatabase(
      path,
      version: schemaVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<String> getDatabaseFilePath() async {
    final dbPath = await getDatabasesPath();
    return join(dbPath, dbFileName);
  }

  static Future<void> closeDatabase() async {
    if (_database == null) return;
    await _database!.close();
    _database = null;
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE daily_tasks (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        type TEXT NOT NULL,
        status TEXT NOT NULL,
        points INTEGER NOT NULL,
        progress INTEGER NOT NULL,
        target_count INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        deadline TEXT,
        logic_date TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE long_term_plans (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        deadline TEXT NOT NULL,
        progress_count INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        status TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE long_term_plan_history (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        deadline TEXT NOT NULL,
        progress_count INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        finished_at TEXT NOT NULL,
        status TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE point_records (
        id TEXT PRIMARY KEY,
        delta INTEGER NOT NULL,
        type TEXT NOT NULL,
        source TEXT NOT NULL,
        remark TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE app_settings (
        key TEXT PRIMARY KEY,
        day_start_time TEXT NOT NULL,
        short_task_base_capacity INTEGER NOT NULL,
        fixed_task_base_capacity INTEGER NOT NULL,
        short_task_current_capacity INTEGER NOT NULL,
        fixed_task_current_capacity INTEGER NOT NULL
      )
    ''');

    await db.insert(
      'app_settings',
      {
        'key': 'app_settings',
        'day_start_time': '00:00',
        'short_task_base_capacity': 3,
        'fixed_task_base_capacity': 5,
        'short_task_current_capacity': 3,
        'fixed_task_current_capacity': 5,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    await db.execute('''
      CREATE TABLE app_runtime_state (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE fixed_plan_templates (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        points INTEGER NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE daily_settlements (
        logic_date TEXT PRIMARY KEY,
        daily_total_count INTEGER NOT NULL,
        daily_completed_count INTEGER NOT NULL,
        fixed_total_count INTEGER NOT NULL,
        fixed_completed_count INTEGER NOT NULL,
        is_perfect_attendance INTEGER NOT NULL,
        bonus_points INTEGER NOT NULL,
        settled_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE reward_items (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        cost INTEGER NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE wheel_sequences (
        id TEXT PRIMARY KEY,
        logic_date TEXT NOT NULL,
        type TEXT NOT NULL,
        target_id TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
  }

  static Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE long_term_plans (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          description TEXT NOT NULL,
          deadline TEXT NOT NULL,
          progress_count INTEGER NOT NULL,
          created_at TEXT NOT NULL,
          status TEXT NOT NULL
        )
      ''');
    }

    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE long_term_plan_history (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          description TEXT NOT NULL,
          deadline TEXT NOT NULL,
          progress_count INTEGER NOT NULL,
          created_at TEXT NOT NULL,
          finished_at TEXT NOT NULL,
          status TEXT NOT NULL
        )
      ''');
    }

    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE point_records (
          id TEXT PRIMARY KEY,
          delta INTEGER NOT NULL,
          type TEXT NOT NULL,
          source TEXT NOT NULL,
          remark TEXT NOT NULL,
          created_at TEXT NOT NULL
        )
      ''');
    }

    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE app_settings (
          key TEXT PRIMARY KEY,
          day_start_time TEXT NOT NULL,
          short_task_base_capacity INTEGER NOT NULL DEFAULT 3,
          fixed_task_base_capacity INTEGER NOT NULL DEFAULT 5,
          short_task_current_capacity INTEGER NOT NULL DEFAULT 3,
          fixed_task_current_capacity INTEGER NOT NULL DEFAULT 5
        )
      ''');

      await db.insert(
        'app_settings',
        {
          'key': 'app_settings',
          'day_start_time': '00:00',
          'short_task_base_capacity': 3,
          'fixed_task_base_capacity': 5,
          'short_task_current_capacity': 3,
          'fixed_task_current_capacity': 5,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    if (oldVersion < 6) {
      await db.execute('''
        CREATE TABLE app_runtime_state (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL
        )
      ''');
    }

    if (oldVersion < 7) {
      await db.execute('''
        ALTER TABLE daily_tasks ADD COLUMN logic_date TEXT NOT NULL DEFAULT ''
      ''');
    }

    if (oldVersion < 8) {
      await db.execute('''
        CREATE TABLE fixed_plan_templates (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          description TEXT NOT NULL,
          points INTEGER NOT NULL,
          created_at TEXT NOT NULL
        )
      ''');
    }

    if (oldVersion < 9) {
      await db.execute('''
        ALTER TABLE app_settings ADD COLUMN short_task_base_capacity INTEGER NOT NULL DEFAULT 3
      ''');
      await db.execute('''
        ALTER TABLE app_settings ADD COLUMN fixed_task_base_capacity INTEGER NOT NULL DEFAULT 5
      ''');
      await db.execute('''
        ALTER TABLE app_settings ADD COLUMN short_task_current_capacity INTEGER NOT NULL DEFAULT 3
      ''');
      await db.execute('''
        ALTER TABLE app_settings ADD COLUMN fixed_task_current_capacity INTEGER NOT NULL DEFAULT 5
      ''');
    }

    if (oldVersion < 10) {
      await db.execute('''
        CREATE TABLE daily_settlements (
          logic_date TEXT PRIMARY KEY,
          daily_total_count INTEGER NOT NULL,
          daily_completed_count INTEGER NOT NULL,
          fixed_total_count INTEGER NOT NULL,
          fixed_completed_count INTEGER NOT NULL,
          is_perfect_attendance INTEGER NOT NULL,
          bonus_points INTEGER NOT NULL,
          settled_at TEXT NOT NULL
        )
      ''');
    }

    if (oldVersion < 11) {
      await db.execute('''
        CREATE TABLE reward_items (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          cost INTEGER NOT NULL,
          created_at TEXT NOT NULL
        )
      ''');
    }

    if (oldVersion < 12) {
      await db.execute('''
        CREATE TABLE wheel_sequences (
          id TEXT PRIMARY KEY,
          logic_date TEXT NOT NULL,
          type TEXT NOT NULL,
          target_id TEXT NOT NULL,
          created_at TEXT NOT NULL
        )
      ''');
    }
  }
}
