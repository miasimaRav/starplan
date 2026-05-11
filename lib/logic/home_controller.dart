import '../data/database.dart';
import '../data/models/day_status.dart';
import '../data/models/task_model.dart';

class HomeController {
  final DatabaseHelper db = DatabaseHelper.instance;

  // Получить задачи на дату (учитывая многодневные)
  Future<List<Task>> loadTasks(DateTime date) async {
    return await db.getTasksBetweenDates(
      start: DateTime(date.year, date.month, date.day, 0, 0, 0),
      end: DateTime(date.year, date.month, date.day, 23, 59, 59),
    );
  }

  Future<Map<String, int>> loadDayStats(DateTime date) async {
    return await db.getTasksCountForDate(date);
  }

  Future<Map<DateTime, DayStatus>> loadMonthStats(DateTime month) async {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    final statsMap = await db.getMonthDayStats(start: start, end: end);

    final Map<DateTime, DayStatus> result = {};

    statsMap.forEach((date, value) {
      final done = value['done'] ?? 0;
      final total = value['total'] ?? 0;

      if (total == 0) return;

      DayType type;
      if (done == total) {
        type = DayType.completed;
      } else if (done == 0) {
        type = DayType.failed;
      } else {
        type = DayType.warning;
      }

      result[date] = DayStatus(
        doneTasks: done,
        totalTasks: total,
        type: type,
      );
    });

    return result;
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

  /// Обновление выполнения задачи с учётом даты (для многодневных задач)
  Future<void> updateTaskProgress({
    required int taskId,
    required DateTime date,
    required bool completed,
  }) async {
    await db.updateTaskCompleted(
      taskId: taskId,
      date: date,
      completed: completed,
    );
  }
}