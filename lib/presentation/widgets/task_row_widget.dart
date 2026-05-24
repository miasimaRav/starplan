import 'package:flutter/material.dart';
import '../../../data/models/task_model.dart';

class TaskRowWidget extends StatefulWidget {
  final Task task;
  final VoidCallback onDelete;
  final ValueChanged<bool?> onChanged;

  const TaskRowWidget({
    super.key,
    required this.task,
    required this.onDelete,
    required this.onChanged,
  });

  @override
  State<TaskRowWidget> createState() => _TaskRowWidgetState();
}

class _TaskRowWidgetState extends State<TaskRowWidget> {
  late bool isCompleted;

  @override
  void initState() {
    super.initState();
    isCompleted = widget.task.completed;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Получаем текущую тему

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              widget.task.title,
              style: TextStyle(
                // Текст берет цвет из темы (белый для темных, темно-серый для светлой)
                color: theme.colorScheme.onSurface,
                fontSize: 14,
              ),
            ),
          ),
          Checkbox(
            value: isCompleted,
            // Цвет самого квадратика, когда галочка стоит (главный цвет темы)
            activeColor: theme.colorScheme.primary,
            // Цвет самой галочки внутри квадратика (всегда черный для отличного контраста)
            checkColor: theme.colorScheme.onPrimary,
            // Цвет рамки пустого квадратика
            side: BorderSide(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
              width: 2,
            ),
            onChanged: (value) {
              if (value == null) return;
              setState(() => isCompleted = value);
              widget.onChanged(value);
            },
          ),
        ],
      ),
    );
  }
}