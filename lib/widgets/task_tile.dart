import 'package:flutter/material.dart';
import '../models/task.dart';

typedef VoidVoid = Future<void> Function();

class TaskTile extends StatelessWidget {
  final Task task;
  final VoidVoid? onToggle;
  final VoidCallback? onEdit;
  final VoidVoid? onDelete;
  final String? dateText;

  const TaskTile({
    super.key,
    required this.task,
    this.onToggle,
    this.onEdit,
    this.onDelete,
    this.dateText,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        leading: IconButton(
          icon: Icon(
            task.isCompleted
                ? Icons.check_circle
                : Icons.radio_button_unchecked,
            color: task.isCompleted ? Colors.green : Colors.grey,
          ),
          onPressed: () async {
            if (onToggle != null) await onToggle!();
          },
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.isCompleted
                ? TextDecoration.lineThrough
                : TextDecoration.none,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            task.description.isNotEmpty
                ? Text(
                    task.description,
                    style: TextStyle(
                      decoration: task.isCompleted
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  )
                : SizedBox.shrink(),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '⏰ $dateText',
                style: TextStyle(
                  fontSize: 12,
                  color: dateText != null ? Colors.grey : Colors.transparent,
                ),
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.edit), onPressed: onEdit),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
