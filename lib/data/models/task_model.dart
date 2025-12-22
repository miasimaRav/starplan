class Task {
  final int? id;
  final String title;
  final String? description;
  final int difficulty;
  final DateTime? startDate;
  final DateTime? endDate;
  final int stars;
  final bool completed;

  Task({
    this.id,
    required this.title,
    this.description,
    this.difficulty = 1,
    this.startDate,
    this.endDate,
    this.stars = 0,
    this.completed = false,
  });

  factory Task.fromMap(Map<String, dynamic> map) => Task(
    id: map['id'] as int?,
    title: map['title'] as String,
    description: map['description'] as String?,
    difficulty: map['difficulty'] as int? ?? 1,
    startDate: map['start_date'] != null
        ? DateTime.tryParse(map['start_date'] as String)
        : null,
    endDate: map['end_date'] != null
        ? DateTime.tryParse(map['end_date'] as String)
        : null,
    stars: map['stars'] as int? ?? 0,
    completed: (map['completed'] as int? ?? 0) == 1,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'description': description,
    'difficulty': difficulty,
    'start_date': startDate?.toIso8601String(),
    'end_date': endDate?.toIso8601String(),
    'stars': stars,
    'completed': completed ? 1 : 0,
  };
}
