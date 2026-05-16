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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              widget.task.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
          Checkbox(
            value: isCompleted,
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