enum DayType { completed, failed, warning }

class DayStatus {
  final int doneTasks;   // выполнено задач в этот день
  final int totalTasks;  // всего задач в этот день
  final DayType type;    // какой цвет/статус для календаря

  DayStatus({
    required this.doneTasks,
    required this.totalTasks,
    required this.type,
  });
}
