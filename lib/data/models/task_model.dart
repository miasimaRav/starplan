import 'package:starplan/data/models/sub_tasks_model.dart';

class DayTask {
  final int id;
  final String title;
  final String? description;
  final int difficulty;
  final DateTime startDate;
  final DateTime? endDate;
  final int stars;
  bool completed;
  final List<DaySubTask> subTasks;

  DayTask({
    required this.id,
    required this.title,
    this.description,
    required this.difficulty,
    required this.startDate,
    this.endDate,
    required this.stars,
    this.completed = false,
    this.subTasks = const [],
  });
}