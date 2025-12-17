class DaySubTask {
  final int id;
  final String subTitle;
  final DateTime subDate;
  final int taskId;
  bool completed;

  DaySubTask({
    required this.id,
    required this.subTitle,
    required this.subDate,
    required this.taskId,
    this.completed = false,
  });
}