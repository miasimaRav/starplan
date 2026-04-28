import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../presentation/pages/home_page.dart';
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
    try {
      final dbPath = await getDatabasesPath();
      print("Путь к базам: $dbPath");

      final path = join(dbPath, fileName);
      print("Полный путь к файлу: $path");

      return await openDatabase(
        path,
        version: 2,                    // увеличиваем версию при изменении структуры
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    } catch (e, stack) {
      print("Критическая ошибка при создании/открытии базы: $e");
      print("Стек: $stack");
      rethrow;
    }
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
        stars INTEGER DEFAULT 100,
        welcome_bonus_received INTEGER DEFAULT 0
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
      'registration_date': now.toIso8601String(),
      'stars': 100,
      'level': 1,
      'welcome_bonus_received': 1
    });

    await _initDefaultUpgrades(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print("Обновление базы с версии $oldVersion на $newVersion");
    // можно добавлять новые столбцы при обновлении версии
  }

  Future close() async {
    final db = _db;
    if (db != null) {
      await db.close();
    }
  }

  // Инициализация начальных предметов магазина
  Future<void> _initDefaultUpgrades(Database db) async {
    final batch = db.batch();

    // Темы
    batch.insert('upgrades', {
      'name': 'Тёмная тема',
      'type': 'theme',
      'cost': 350,
      'purchased': 0,
    });

    batch.insert('upgrades', {
      'name': 'Космическая тема',
      'type': 'theme',
      'cost': 750,
      'purchased': 0,
    });

    // Аватары
    batch.insert('upgrades', {
      'name': 'Аватар "Воин Света"',
      'type': 'avatar',
      'cost': 500,
      'purchased': 0,
    });

    batch.insert('upgrades', {
      'name': 'Аватар "Звёздный Маг"',
      'type': 'avatar',
      'cost': 650,
      'purchased': 0,
    });

    // Награды / трофеи
    batch.insert('upgrades', {
      'name': 'Бронзовый трофей',
      'type': 'trophy',
      'cost': 200,
      'purchased': 0,
    });

    batch.insert('upgrades', {
      'name': 'Серебряный трофей',
      'type': 'trophy',
      'cost': 550,
      'purchased': 0,
    });

    batch.insert('upgrades', {
      'name': 'Золотой трофей',
      'type': 'trophy',
      'cost': 1100,
      'purchased': 0,
    });

    await batch.commit(noResult: true);
    print('Начальные улучшения магазина успешно добавлены');
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    final db = await database;
    final result = await db.query('users', limit: 1);
    return result.isNotEmpty ? result.first : null;
  }

  // Универсальный метод обновления пользователя (основной)
  Future<void> updateUserData({
    required int id,
    String? name,
    String? birthDate,
    String? email,
    int? level,
    int? stars,
  }) async {
    final db = await database;
    final values = <String, dynamic>{};

    if (name != null) values['name'] = name;
    if (birthDate != null) values['birth_date'] = birthDate;
    if (email != null) values['email'] = email;
    if (level != null) values['level'] = level;
    if (stars != null) values['stars'] = stars;

    if (values.isEmpty) return;

    await db.update(
      'users',
      values,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

// Удобные обёртки (оставляем для читаемости кода)
  Future<void> updateUserStars(int userId, int stars) async {
    await updateUserData(id: userId, stars: stars);
  }

  Future<void> updateUser({
    required int id,
    required String name,
    required String? birthDate,
    required String? email,
    required int level,
  }) async {
    await updateUserData(
      id: id,
      name: name,
      birthDate: birthDate,
      email: email,
      level: level,
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
  }) async {
    try {
      final db = await database;
      print("База открыта успешно, вставляем задачу");

      await db.insert('tasks', {
        'title': title,
        'description': description,
        'difficulty': difficulty,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        'stars': stars,
        'completed': completed ? 1 : 0,
      });

      print("Задача успешно добавлена");
    } catch (e, stack) {
      print("ОШИБКА при вставке задачи: $e");
      print("Стек: $stack");
      rethrow; // или обработать как хочешь
    }
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

  Future<Map<DateTime, DayStatus>> getMonthStats(DateTime month) async {
    final db = await database;

    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    final result = await db.rawQuery(
      '''
    SELECT 
      date(start_date) as day,
      COUNT(*) as total,
      SUM(completed) as done
    FROM tasks
    WHERE start_date BETWEEN ? AND ?
    GROUP BY day
    ''',
      [start.toIso8601String(), end.toIso8601String()],
    );

    final Map<DateTime, DayStatus> map = {};

    for (final row in result) {
      final date = DateTime.parse(row['day'] as String);
      final total = row['total'] as int;
      final done = row['done'] as int? ?? 0;

      final type = done == 0
          ? DayType.failed
          : done == total
          ? DayType.completed
          : DayType.warning;

      map[date] = DayStatus(
        doneTasks: done,
        totalTasks: total,
        type: type,
      );
    }

    return map;
  }

  Future<void> updateTaskCompleted(int taskId, bool completed) async {
    final db = await database;
    await db.update(
      'tasks',
      {'completed': completed ? 1 : 0},
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  /// Возвращает статистику по дням за месяц
  /// key   — DateTime(yyyy-mm-dd)
  /// value — { 'done': int, 'total': int }
  Future<Map<DateTime, Map<String, int>>> getMonthDayStats({
    required DateTime start,
    required DateTime end,
  }) async {
    final db = await database;

    final result = await db.rawQuery(
      '''
    SELECT
      DATE(start_date) AS day,
      SUM(CASE WHEN completed = 1 THEN 1 ELSE 0 END) AS done,
      COUNT(*) AS total
    FROM tasks
    WHERE start_date BETWEEN ? AND ?
    GROUP BY DATE(start_date)
    ''',
      [
        start.toIso8601String(),
        end.toIso8601String(),
      ],
    );

    final Map<DateTime, Map<String, int>> stats = {};

    for (final row in result) {
      final dayString = row['day'] as String;

      // SQLite DATE() → yyyy-MM-dd
      final dateParts = dayString.split('-');
      final date = DateTime(
        int.parse(dateParts[0]),
        int.parse(dateParts[1]),
        int.parse(dateParts[2]),
      );

      stats[date] = {
        'done': (row['done'] as int?) ?? 0,
        'total': (row['total'] as int?) ?? 0,
      };
    }

    return stats;
  }

  Future<int> deleteTask(int id) async {
    final db = await instance.database;
    return await db.delete(
      'tasks',              // имя таблицы
      where: 'id = ?',      // условие
      whereArgs: [id],      // аргументы для подстановки
    );
  }

// Получить текущий баланс звёзд пользователя
  Future<int> getUserStars() async {
    final user = await getCurrentUser();
    return user?['stars'] as int? ?? 100;
  }

// Списать звёзды (уменьшить баланс)
  Future<void> deductStars(int amount) async {
    final user = await getCurrentUser();
    if (user == null) return;

    final currentStars = user['stars'] as int;
    final newStars = currentStars - amount;

    if (newStars < 0) return; // не даём уйти в минус

    final userId = user['id'] as int;
    await updateUserStars(userId, newStars);
  }

  //TODO: проверить используется ли этот метод
// Купить улучшение / предмет
  Future<bool> purchaseUpgrade(int upgradeId, int cost) async {
    try {
      final user = await getCurrentUser();
      if (user == null) return false;

      final currentStars = user['stars'] as int;
      if (currentStars < cost) {
        print("Недостаточно звёзд. Нужно: $cost, Есть: $currentStars");
        return false;
      }

      final db = await database;

      // Проверка на уже купленное
      final existing = await db.query(
        'upgrades',
        where: 'id = ? AND purchased = 1',
        whereArgs: [upgradeId],
      );
      if (existing.isNotEmpty) return false; // уже куплено

      // Списываем звёзды
      final newBalance = currentStars - cost;
      final userId = user['id'] as int;

      await db.update(
        'users',
        {'stars': newBalance},
        where: 'id = ?',
        whereArgs: [userId],
      );

      // Отмечаем как куплено
      await db.update(
        'upgrades',
        {'purchased': 1},
        where: 'id = ?',
        whereArgs: [upgradeId],
      );

      print("Покупка успешна. Новый баланс: $newBalance");
      return true;
    } catch (e) {
      print("Ошибка при покупке: $e");
      return false;
    }
  }

// Получить все предметы магазина (с информацией куплено/не куплено)
  Future<List<Map<String, dynamic>>> getShopItems() async {
    final db = await database;
    return await db.query('upgrades', orderBy: 'cost ASC');
  }

// Добавить начальные предметы в магазин (вызвать один раз, например в initState приложения или при первом запуске)
  Future<void> initShopItems() async {
    final db = await database;

    // Проверяем, есть ли уже записи
    final countResult = await db.rawQuery('SELECT COUNT(*) as cnt FROM upgrades');
    final count = Sqflite.firstIntValue(countResult) ?? 0;

    if (count > 0) {
      print("Магазин уже инициализирован ($count товаров)");
      return;
    }

    print("Инициализация магазина — добавляем товары");

    final batch = db.batch();

    // Темы
    batch.insert('upgrades', {
      'name': 'Тёмная тема',
      'type': 'theme',
      'cost': 300,
      'purchased': 0,
    });
    batch.insert('upgrades', {
      'name': 'Космическая тема',
      'type': 'theme',
      'cost': 800,
      'purchased': 0,
    });

    // Аватары
    batch.insert('upgrades', {
      'name': 'Аватар "Воин"',
      'type': 'avatar',
      'cost': 450,
      'purchased': 0,
    });
    batch.insert('upgrades', {
      'name': 'Аватар "Маг"',
      'type': 'avatar',
      'cost': 700,
      'purchased': 0,
    });

    // Награды / трофеи
    batch.insert('upgrades', {
      'name': 'Бронзовый трофей',
      'type': 'trophy',
      'cost': 250,
      'purchased': 0,
    });
    batch.insert('upgrades', {
      'name': 'Серебряный трофей',
      'type': 'trophy',
      'cost': 600,
      'purchased': 0,
    });
    batch.insert('upgrades', {
      'name': 'Золотой трофей',
      'type': 'trophy',
      'cost': 1200,
      'purchased': 0,
    });

    await batch.commit(noResult: true);
    print("Добавлено ${await db.rawQuery('SELECT COUNT(*) FROM upgrades')} товаров");
  }

}
