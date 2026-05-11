import 'package:flutter/material.dart';
import '../../../data/models/task_model.dart';

class TaskRowWidget extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              task.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
          Checkbox(
            value: task.completed,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}