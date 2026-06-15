import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import 'models/day_status.dart';
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
        version: 10, // Увеличили версию базы данных из-за изменения схемы
        onConfigure: (db) async {
          // Включаем поддержку внешних ключей (FOREIGN KEYS) в SQLite
          await db.execute('PRAGMA foreign_keys = ON');
        },
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
    // 1. Создаем таблицу пользователей
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        registration_date TEXT NOT NULL,
        birth_date TEXT,
        email TEXT,
        level INTEGER DEFAULT 1,
        stars INTEGER DEFAULT 110,
        welcome_bonus_received INTEGER DEFAULT 1
      )
    ''');

    // 2. Создаем таблицу задач (добавлен user_id и FOREIGN KEY)
    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        difficulty INTEGER,
        start_date TEXT,
        end_date TEXT,
        stars INTEGER NOT NULL,
        completed INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    // 3. Создаем справочник улучшений (магазин)
    await db.execute('''
      CREATE TABLE upgrades (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT,
        cost INTEGER NOT NULL,
        purchased INTEGER DEFAULT 0,
        icon_path TEXT,
        key TEXT
      )
    ''');

    // 4. Создаем таблицу достижений (добавлен FOREIGN KEY)
    await db.execute('''
      CREATE TABLE user_achievements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        achievement_key TEXT NOT NULL,
        completed INTEGER DEFAULT 0,
        date_completed TEXT,
        stars_rewarded INTEGER DEFAULT 0,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        UNIQUE(user_id, achievement_key)
      )
    ''');

    // 5. Создаем таблицу прогресса (добавлен FOREIGN KEY)
    await db.execute('''
      CREATE TABLE task_progress (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        task_id INTEGER NOT NULL,
        date TEXT NOT NULL,                    -- yyyy-mm-dd
        completed INTEGER DEFAULT 0,
        FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE,
        UNIQUE(task_id, date)
      )
    ''');

    // Стартовый пользователь
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
    print("Обновление базы данных с версии $oldVersion на $newVersion");
    // Здесь можно добавлять следующие миграции, если потребуются
  }

  Future close() async {
    final db = _db;
    if (db != null) {
      await db.close();
    }
  }

  // Инициализация начальных предметов магазина
  Future<void> _initDefaultUpgrades(Database db) async {
    final countResult = await db.rawQuery('SELECT COUNT(*) as cnt FROM upgrades');
    final count = Sqflite.firstIntValue(countResult) ?? 0;
    if (count > 0) {
      print("Магазин уже инициализирован ($count товаров)");
      return;
    }

    print("Инициализация магазина — добавляем товары...");
    final batch = db.batch();

    batch.insert('upgrades', {
      'name': 'Станция "Земля"',
      'type': 'theme',
      'cost': 0,
      'purchased': 1,
      'icon_path': 'assets/images/icons/theme_earth.png',
      'key': 'default',
    });

    batch.insert('upgrades', {
      'name': 'Сверхновая',
      'type': 'theme',
      'cost': 70,
      'purchased': 0,
      'icon_path': 'assets/images/icons/theme_supernova.png',
      'key': 'supernova',
    });

    batch.insert('upgrades', {
      'name': 'Глубокий космос',
      'type': 'theme',
      'cost': 140,
      'purchased': 0,
      'icon_path': 'assets/images/icons/theme_space.png',
      'key': 'space',
    });

    batch.insert('upgrades', {
      'name': 'Инициалы SP',
      'type': 'avatar',
      'cost': 0,
      'purchased': 1,
      'icon_path': 'assets/images/icons/avatar_sp.png',
      'key': 'default',
    });

    batch.insert('upgrades', {
      'name': 'Космический Кот',
      'type': 'avatar',
      'cost': 50,
      'purchased': 0,
      'icon_path': 'assets/images/icons/avatar_cat.jpg',
      'key': 'cat',
    });

    batch.insert('upgrades', {
      'name': 'Звёздный Дракон',
      'type': 'avatar',
      'cost': 100,
      'purchased': 0,
      'icon_path': 'assets/images/icons/avatar_dragon.jpg',
      'key': 'dragon',
    });

    batch.insert('upgrades', {
      'name': 'Бронзовый трофей',
      'type': 'trophy',
      'cost': 30,
      'purchased': 0,
      'icon_path': 'assets/images/icons/trophy_bronze.png',
      'key': 'bronze'
    });

    batch.insert('upgrades', {
      'name': 'Серебряный трофей',
      'type': 'trophy',
      'cost': 70,
      'purchased': 0,
      'icon_path': 'assets/images/icons/trophy_silver.png',
      'key': 'silver'
    });

    batch.insert('upgrades', {
      'name': 'Золотой трофей',
      'type': 'trophy',
      'cost': 150,
      'purchased': 0,
      'icon_path': 'assets/images/icons/trophy_gold.png',
      'key': 'gold'
    });

    await batch.commit(noResult: true);
    print('Начальные улучшения магазина успешно добавлены (9 товаров)');
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    final db = await database;
    final result = await db.query('users', limit: 1);
    return result.isNotEmpty ? result.first : null;
  }

  // Универсальный метод обновления пользователя
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

  Future<void> updateUserStars(int userId, int stars) async {
    await updateUserData(id: userId, stars: stars);
    print("STARS UPDATE: user=$userId value=$stars");
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

  // Обновлен метод создания задачи — теперь он привязывает задачу к пользователю
  Future<void> insertTask({
    required String title,
    required String? description,
    required int difficulty,
    required DateTime startDate,
    required DateTime endDate,
    required int stars,
    required bool completed,
  }) async {
    final db = await database;
    print("База открыта успешно, вставляем задачу");

    // Получаем текущего пользователя для привязки задачи
    final user = await getCurrentUser();
    final userId = user != null ? user['id'] : 1;

    final taskId = await db.insert('tasks', {
      'user_id': userId, // Привязка к внешнему ключу
      'title': title,
      'description': description,
      'difficulty': difficulty,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'stars': stars,
      'completed': 0,
    });

    DateTime current = startDate;

    while (!current.isAfter(endDate)) {
      await db.insert('task_progress', {
        'task_id': taskId,
        'date': current.toIso8601String().substring(0, 10),
        'completed': 0,
      });

      current = current.add(const Duration(days: 1));
    }
  }

  Future<List<Task>> getTasksBetweenDates({
    required DateTime start,
    required DateTime end,
  }) async {
    final db = await database;

    final result = await db.query(
      'tasks',
      where: 'start_date <= ? AND end_date >= ?',
      whereArgs: [
        end.toIso8601String(),
        start.toIso8601String(),
      ],
      orderBy: 'start_date ASC',
    );

    final List<Task> tasks = [];

    for (final row in result) {
      final task = Task.fromMap(row);

      task.completed = await isTaskCompletedOnDate(
        task.id!,
        start,
      );

      tasks.add(task);
    }

    return tasks;
  }

  Future<Task?> getTaskById(int id) async {
    final db = await database;
    final maps = await db.query(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Task.fromMap(maps.first);
    }
    return null;
  }

  Future<bool> isTaskCompletedOnDate(int taskId, DateTime date) async {
    final db = await database;
    final dateStr = date.toIso8601String().substring(0, 10);

    final result = await db.rawQuery('''
      SELECT COUNT(*) as count 
      FROM task_progress 
      WHERE task_id = ? 
        AND date = ? 
        AND completed = 1
    ''', [taskId, dateStr]);

    return (Sqflite.firstIntValue(result) ?? 0) > 0;
  }

  Future<void> updateTaskProgress(int taskId, DateTime date, bool completed) async {
    final db = await database;
    final dateStr = date.toIso8601String().substring(0, 10);

    if (completed) {
      await db.insert(
        'task_progress',
        {
          'task_id': taskId,
          'date': dateStr,
          'completed': 1,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } else {
      await db.delete(
        'task_progress',
        where: 'task_id = ? AND date = ?',
        whereArgs: [taskId, dateStr],
      );
    }
  }

  Future<int> getTaskProgress(int taskId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM task_progress WHERE task_id = ? AND completed = 1',
      [taskId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> updateTaskCompleted({
    required int taskId,
    required DateTime date,
    required bool completed,
  }) async {
    final db = await database;
    final dateStr = date.toIso8601String().substring(0, 10);

    await db.insert(
      'task_progress',
      {
        'task_id': taskId,
        'date': dateStr,
        'completed': completed ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    print("Задача $taskId на $dateStr отмечена как ${completed ? 'выполненная' : 'невыполненная'}");
  }

  Future<void> updateTask({
    required int id,
    String? title,
    String? description,
    int? difficulty,
    DateTime? startDate,
    DateTime? endDate,
    int? stars,
  }) async {
    final db = await database;
    await db.update(
      'tasks',
      {
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (difficulty != null) 'difficulty': difficulty,
        if (startDate != null) 'start_date': startDate.toIso8601String(),
        if (endDate != null) 'end_date': endDate.toIso8601String(),
        if (stars != null) 'stars': stars,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Map<String, int>> getTasksCountForDate(DateTime date) async {
    final db = await database;
    final dateStr = date.toIso8601String().substring(0, 10);

    final result = await db.rawQuery('''
      SELECT
        COUNT(*) as total,
        SUM(completed) as done
      FROM task_progress
      WHERE date = ?
    ''', [dateStr]);

    final row = result.first;

    return {
      'total': row['total'] as int? ?? 0,
      'done': row['done'] as int? ?? 0,
    };
  }

  Future<Map<DateTime, DayStatus>> getMonthStats(DateTime month) async {
    final db = await database;

    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0);

    final result = await db.rawQuery('''
      SELECT
        date,
        COUNT(*) as total,
        SUM(completed) as done
      FROM task_progress
      WHERE date BETWEEN ? AND ?
      GROUP BY date
    ''', [
      start.toIso8601String().substring(0, 10),
      end.toIso8601String().substring(0, 10),
    ]);

    final Map<DateTime, DayStatus> stats = {};

    for (final row in result) {
      final date = DateTime.parse(row['date'] as String);
      final total = row['total'] as int;
      final done = row['done'] as int? ?? 0;

      stats[date] = DayStatus(
        doneTasks: done,
        totalTasks: total,
        type: done == 0
            ? DayType.failed
            : done == total
            ? DayType.completed
            : DayType.warning,
      );
    }

    return stats;
  }

  Future<Map<DateTime, Map<String, int>>> getMonthDayStats({
    required DateTime start,
    required DateTime end,
  }) async {
    final db = await database;

    final result = await db.rawQuery('''
      SELECT 
        date(start_date) as day,
        COUNT(*) as total,
        SUM(CASE WHEN completed = 1 THEN 1 ELSE 0 END) as done
      FROM tasks
      WHERE (start_date <= ? AND end_date >= ?)
      GROUP BY date(start_date)
    ''', [
      end.toIso8601String(),
      start.toIso8601String(),
    ]);

    final Map<DateTime, Map<String, int>> stats = {};

    for (final row in result) {
      final dayString = row['day'] as String;

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
    final db = await database;

    await db.delete(
      'task_progress',
      where: 'task_id = ?',
      whereArgs: [id],
    );

    return await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> getUserStars() async {
    final db = await database;

    final result = await db.query(
      'users',
      columns: ['stars'],
      limit: 1,
      orderBy: 'id DESC',
    );

    return result.isNotEmpty ? (result.first['stars'] as int) : 100;
  }

  Future<void> deductStars(int amount) async {
    final user = await getCurrentUser();
    if (user == null) return;

    final currentStars = user['stars'] as int;
    final newStars = currentStars - amount;

    if (newStars < 0) return;

    final userId = user['id'] as int;
    await updateUserStars(userId, newStars);
  }

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

      final existing = await db.query(
        'upgrades',
        where: 'id = ? AND purchased = 1',
        whereArgs: [upgradeId],
      );
      if (existing.isNotEmpty) return false;

      final newBalance = currentStars - cost;
      final userId = user['id'] as int;

      await db.update(
        'users',
        {'stars': newBalance},
        where: 'id = ?',
        whereArgs: [userId],
      );

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

  Future<List<Map<String, dynamic>>> getShopItems() async {
    final db = await database;
    return await db.query('upgrades', orderBy: 'cost ASC');
  }

  Future<int> getCompletedTasksCount() async {
    final db = await database;

    final result = await db.rawQuery('''
      SELECT COUNT(*) as count
      FROM task_progress
      WHERE completed = 1
    ''');

    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getCurrentStreak() async {
    final db = await database;

    final result = await db.rawQuery('''
      WITH dates AS (
        SELECT DISTINCT date
        FROM task_progress
        WHERE completed = 1
      )
      SELECT COUNT(*) as streak 
      FROM (
        SELECT date,
               JULIANDAY(date) - ROW_NUMBER() OVER (ORDER BY date) as grp
        FROM dates
      ) 
      GROUP BY grp 
      ORDER BY MAX(date) DESC 
      LIMIT 1
    ''');

    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getStreakRecord() async {
    final db = await database;

    final result = await db.rawQuery('''
    WITH dates AS (
      SELECT DISTINCT date 
      FROM task_progress 
      WHERE completed = 1
    )
    SELECT IFNULL(MAX(streak), 0) as record 
    FROM (
      SELECT COUNT(*) as streak
      FROM (
        SELECT date,
               JULIANDAY(date) - ROW_NUMBER() OVER (ORDER BY date) as grp
        FROM dates
      ) 
      GROUP BY grp
    )
  ''');

    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<Map<String, dynamic>>> getUserAchievements(int userId) async {
    final db = await database;
    return await db.query(
      'user_achievements',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  Future<void> unlockAchievement({
    required int userId,
    required String achievementKey,
    required int starsReward,
  }) async {
    final db = await database;

    await db.insert(
      'user_achievements',
      {
        'user_id': userId,
        'achievement_key': achievementKey,
        'completed': 1,
        'date_completed': DateTime.now().toIso8601String(),
        'stars_rewarded': starsReward,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    final currentBalance = await getUserStars();
    final newBalance = currentBalance + starsReward;

    await updateUserStars(userId, newBalance);
    print("Достижение $achievementKey разблокировано! +$starsReward звёзд. Новый баланс: $newBalance");
  }

  Future<bool> isAchievementUnlocked(int userId, String achievementKey) async {
    final db = await database;
    final result = await db.query(
      'user_achievements',
      where: 'user_id = ? AND achievement_key = ? AND completed = 1',
      whereArgs: [userId, achievementKey],
    );
    return result.isNotEmpty;
  }

  Future<String?> getAchievementUnlockDate(int userId, String achievementKey) async {
    final db = await database;
    final result = await db.query(
      'user_achievements',
      columns: ['date_completed'],
      where: 'user_id = ? AND achievement_key = ? AND completed = 1',
      whereArgs: [userId, achievementKey],
    );

    if (result.isNotEmpty && result.first['date_completed'] != null) {
      return result.first['date_completed'] as String;
    }
    return null;
  }
}