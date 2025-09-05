import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';

class TaskTile extends ConsumerWidget {
  final int index;
  final Task task;

  const TaskTile({super.key, required this.index, required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: Checkbox(
        value: task.isCompleted,
        onChanged: (_) async {
          final ok = await ref.read(taskProvider.notifier).toggleTask(index);
          if (!ok && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to toggle task')),
            );
          }
        },
      ),
      title: Text(
        task.title,
        style: TextStyle(
          decoration: task.isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(task.description),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditDialog(context, ref),
          ),
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete),
            onPressed: () async {
              final ok = await ref.read(taskProvider.notifier).deleteTask(index);
              if (!ok && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to delete task')),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController(text: task.title);
    final descController = TextEditingController(text: task.description);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Edit Task"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
              TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                final updated = Task(
                  title: titleController.text.trim(),
                  description: descController.text.trim(),
                  isCompleted: task.isCompleted,
                );
                final ok = await ref.read(taskProvider.notifier).updateTask(index, updated);
                if (!ok && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to update task')),
                  );
                }
                if (context.mounted) Navigator.pop(ctx);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }
}
