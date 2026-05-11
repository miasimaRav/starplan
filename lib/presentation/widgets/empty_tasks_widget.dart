import 'package:flutter/material.dart';

class EmptyTasksWidget extends StatelessWidget {
  const EmptyTasksWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "На этот день задач пока нет",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 18,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Нажмите «+» чтобы добавить",
            style: TextStyle(
              color: Colors.white54,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}