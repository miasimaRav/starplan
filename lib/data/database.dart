import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import 'models/task_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _db;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB('starplan.db');
    return _db!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        registration_date TEXT NOT NULL,
        birth_date TEXT,
        email TEXT,
        level INTEGER DEFAULT 1,
        stars INTEGER DEFAULT 100
      )
    ''');

    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        difficulty INTEGER,
        start_date TEXT,
        end_date TEXT,
        stars INTEGER DEFAULT 0,
        completed INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE sub_tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sub_title TEXT NOT NULL,
        sub_date TEXT,
        task_id INTEGER NOT NULL,
        completed INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE upgrades (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT,
        cost INTEGER NOT NULL,
        purchased INTEGER DEFAULT 0
      )
    ''');

    // стартовый пользователь
    final now = DateTime.now();
    await db.insert('users', {
      'name': 'User',
      'registration_date': now,
      'stars': 100,
    });

    //TODO: обдумать какие улучшения могут быть
    // await db.insert('upgrades', {
    //   'name': 'Улучшение',
    //   'type': '',
    //   'cost': 100,
    //   'purchased': 0,
    // });
  }

  Future close() async {
    final db = _db;
    if (db != null) {
      await db.close();
    }
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    final db = await database;
    final result = await db.query('users', limit: 1);
    return result.isNotEmpty ? result.first : null;
  }

  // обновить баланс
  Future<void> updateUserStars(int userId, int stars) async {
    final db = await database;
    await db.update(
      'users',
      {'stars': stars},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<void> updateUser({
    required int id,
    required String name,
    required String? birthDate,
    required String? email,
    required int level,
  }) async {
    final db = await database;
    await db.update(
      'users',
      {
        'name': name,
        'birth_date': birthDate,
        'email': email,
        'level': level,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> insertTask({
    required String title,
    required String? description,
    required int difficulty,
    required DateTime startDate,
    required DateTime endDate,
    required int stars,
    required bool completed,
})async{
    final db = await database;
    await db.insert('tasks', {
      'title': title,
      'description': description,
      'difficulty':difficulty,
      'start_date': startDate,
      'end_date':endDate,
      'stars': stars,
      'completed':completed
    });


}

  Future<List<Task>> getTasksBetweenDates({
    required DateTime start,
    required DateTime end,
  }) async {
    final db = await database;

    // приводим к строкам ISO (как в toMap)
    final startDate = start.toIso8601String();
    final endDate = end.toIso8601String();

    final result = await db.query(
      'tasks',
      where: 'start_date >= ? AND end_date <= ?',
      whereArgs: [startDate, endDate],
      orderBy: 'start_date ASC',
    );

    return result.map((row) => Task.fromMap(row)).toList();
  }

  Future<Map<String, int>> getTasksCountForDate(DateTime date) async {
    final db = await database;

    // диапазон для одного дня [00:00 - 23:59]
    final startOfDay = DateTime(date.year, date.month, date.day, 0, 0, 0);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final startDate = startOfDay.toIso8601String();
    final endDate = endOfDay.toIso8601String();
    // общее количество задач
    final totalResult = await db.rawQuery(
      'SELECT COUNT(*) as total FROM tasks WHERE start_date <= ? AND end_date >= ?',
      [endDate, startDate],);
    // выполненные задачи
    final doneResult = await db.rawQuery(
      'SELECT COUNT(*) as done FROM tasks WHERE completed = 1 AND start_date <= ? AND end_date >= ?',
      [endDate, startDate],
    );
    return {
      'total': (totalResult.first['total'] as int) ?? 0,
      'done': (doneResult.first['done'] as int) ?? 0,};
  }


}
