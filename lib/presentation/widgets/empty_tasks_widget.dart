import 'package:flutter/material.dart';

class EmptyTasksWidget extends StatelessWidget {
  const EmptyTasksWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Получаем текущую тему

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "На этот день задач пока нет",
            style: TextStyle(
              // Используем цвет текста из темы с прозрачностью 70%
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Нажмите «+» чтобы добавить",
            style: TextStyle(
              // Используем цвет текста из темы с прозрачностью 54%
              color: theme.colorScheme.onSurface.withOpacity(0.54),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}