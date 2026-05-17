import '../data/database.dart';
import '../data/models/day_status.dart';
import '../data/models/task_model.dart';

class HomeController {
  final DatabaseHelper db = DatabaseHelper.instance;

  // Получить задачи на дату (учитывая многодневные)
  Future<List<Task>> loadTasks(DateTime date) async {
    final dayStart = DateTime(date.year, date.month, date.day, 0, 0, 0);
    final dayEnd = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return await db.getTasksBetweenDates(
      start: dayStart,
      end: dayEnd,
    );
  }

  Future<Map<String, int>> loadDayStats(DateTime date) async {
    return await db.getTasksCountForDate(date);
  }

// Получить корректную статистику месяца из таблицы прогресса
  Future<Map<DateTime, DayStatus>> loadMonthStats(DateTime month) async {
    // Вызываем уже существующий правильный метод вашего DatabaseHelper
    return await db.getMonthStats(month);
  }

  Future<void> createTask({
    required String title,
    required String? description,
    required int difficulty,
    required DateTime startDate,
    required DateTime endDate,
    required int stars,
  }) async {
    await db.insertTask(
      title: title,
      description: description,
      difficulty: difficulty,
      startDate: startDate,
      endDate: endDate,
      stars: stars,
      completed: false,
    );
  }

  Future<void> deleteTask(int id) async {
    await db.deleteTask(id);
  }

  /// Обновление выполнения задачи с учётом даты и начисления звёзд (Гибридный подход)
  Future<void> updateTaskProgress({
    required int taskId,
    required DateTime date,
    required bool completed,
  }) async {
    // Обновляем статус выполнения в таблице прогресса за конкретный день
    await db.updateTaskCompleted(
      taskId: taskId,
      date: date,
      completed: completed,
    );

    const int userId = 1;

    // Получаем саму задачу из БД, чтобы узнать её параметры (сроки и полную стоимость)
    final task = await db.getTaskById(taskId);
    if (task == null) {
      print("Ошибка: Задача с id $taskId не найдена в базе данных.");
      return;
    }

    // Проверяем даты на null
    if (task.startDate == null || task.endDate == null) {
      print("Ошибка: У задачи с id $taskId отсутствуют даты начала или окончания.");
      return;
    }

    // Создаем локальные не-nullable переменные (благодаря знаку `!`)
    final DateTime startDate = task.startDate!;
    final DateTime endDate = task.endDate!;

    // Нормализуем даты к полуночи (00:00:00), чтобы корректно сравнивать дни без учета часов/минут
    final startMidnight = DateTime(startDate.year, startDate.month, startDate.day);
    final endMidnight = DateTime(endDate.year, endDate.month, endDate.day);
    final currentMidnight = DateTime(date.year, date.month, date.day);

    // Вычисляем полную продолжительность задачи в днях
    final totalDays = endMidnight.difference(startMidnight).inDays + 1;

    int starsToAward = 0;

    if (totalDays <= 1) {
      // Вариант А: Однодневная задача — начисляем/вычитаем полную стоимость
      starsToAward = task.stars;
    } else {
      // Вариант Б: Многодневная задача — Гибридный подход
      final isLastDay = currentMidnight.isAtSameMomentAs(endMidnight);

      if (!isLastDay) {
        // Промежуточный день: даем ровно 1 звездочку за поддержание привычки
        starsToAward = 1;
      } else {
        // Финальный день: отдаем весь оставшийся куш
        // Формула: Общая стоимость - (Количество промежуточных дней * 1 звезда)
        starsToAward = task.stars - (totalDays - 1);

        // Защитная проверка: награда за финальный день не должна быть меньше 1 звезды
        if (starsToAward < 1) starsToAward = 1;
      }
    }

    // получаем текущий баланс пользователя и обновляем его
    final int currentBalance = await db.getUserStars();

    if (completed) {
      // Прибавляем высчитанную награду
      final int newBalance = currentBalance + starsToAward;
      await db.updateUserStars(userId, newBalance);
      print("Гибридный подход (+): начислено $starsToAward звёзд. Новый баланс: $newBalance");
    } else {
      // Если пользователь снял галочку — вычитаем ровно столько же, сколько дали бы за этот день
      int newBalance = currentBalance - starsToAward;
      if (newBalance < 0) newBalance = 0;
      await db.updateUserStars(userId, newBalance);
      print("Гибридный подход (-): списано $starsToAward звёзд. Новый баланс: $newBalance");
    }
  }
}