import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:todo_app/widgets/empty-state.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';
import '../widgets/task_tile.dart';
import '../styles/app_styles.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(taskProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("My To-Do List"),
        centerTitle: true,
      ),
      body: tasks.isEmpty
          ? const EmptyState()
          : ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) => TaskTile(index: index, task: tasks[index]),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    DateTime? selectedDate;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            title: const Text("Add Task"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: "Title"),
                ),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: "Description"),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                      initialDate: DateTime.now(),
                    );
                    if (picked != null) {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (time != null) {
                        selectedDate = DateTime(
                          picked.year, picked.month, picked.day, time.hour, time.minute,
                        );
                        setState(() {}); // refresh selected text
                      }
                    }
                  },
                  icon: const Icon(Icons.calendar_today),
                  label: const Text("Pick Date & Time"),
                ),
                if (selectedDate != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      "Selected: ${DateFormat('dd MMM yyyy, hh:mm a').format(selectedDate!)}",
                      style: AppStyles.smallText,
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
              ElevatedButton(
                onPressed: () async {
                  final title = titleController.text.trim();
                  if (title.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Title is required')),
                    );
                    return;
                  }
                  final ok = await ref.read(taskProvider.notifier).addTask(
                        Task(
                          title: title,
                          description: descController.text.trim(),
                        ),
                        scheduleAt: selectedDate,
                      );
                  if (!ok) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to add task')),
                    );
                  }
                  if (context.mounted) Navigator.pop(ctx);
                },
                child: const Text("Save"),
              ),
            ],
          ),
        );
      },
    );
  }
}
