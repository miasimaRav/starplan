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

  /// Обновление выполнения задачи с учётом даты и начисления звёзд
  Future<void> updateTaskProgress({
    required int taskId,
    required DateTime date,
    required bool completed,
    required int stars,
  }) async {
    // Обновляем статус выполнения в таблице прогресса
    await db.updateTaskCompleted(
      taskId: taskId,
      date: date,
      completed: completed,
    );

    const int userId = 1;

    // Получаем текущий баланс пользователя из базы данных!
    final int currentBalance = await db.getUserStars();

    if (completed) {
      // Прибавляем награду к текущему балансу
      final int newBalance = currentBalance + stars;
      await db.updateUserStars(userId, newBalance);
      print("Звёзды начислены: +$stars. Новый баланс: $newBalance");
    } else {
      // Вычитаем награду из баланса (защита от ухода в минус)
      int newBalance = currentBalance - stars;
      if (newBalance < 0) newBalance = 0;
      await db.updateUserStars(userId, newBalance);
      print("Звёзды списаны: -$stars. Новый баланс: $newBalance");
    }
  }
}