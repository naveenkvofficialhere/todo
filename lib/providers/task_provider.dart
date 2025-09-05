import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/task.dart';
import '../services/notification_service.dart';

final taskProvider = StateNotifierProvider<TaskNotifier, List<Task>>((ref) {
  return TaskNotifier();
});

class TaskNotifier extends StateNotifier<List<Task>> {
  TaskNotifier() : super([]) {
    loadTasks();
  }

  Future<void> loadTasks() async {
    final box = Hive.box<Task>('tasks');
    state = box.values.toList();
  }

  Future<bool> addTask(Task task, {DateTime? scheduleAt}) async {
    try {
      final box = Hive.box<Task>('tasks');
      await box.add(task);
      state = box.values.toList();

      if (scheduleAt != null) {
        await NotificationService.schedule("Task Reminder", task.title, scheduleAt);
      }
      return true;
    } catch (e, st) {
      debugPrint('Add task failed: $e\n$st');
      return false;
    }
  }

  Future<bool> updateTask(int index, Task updatedTask, {DateTime? scheduleAt}) async {
    try {
      final box = Hive.box<Task>('tasks');
      await box.putAt(index, updatedTask);
      state = box.values.toList();

      if (scheduleAt != null) {
        await NotificationService.schedule("Updated Task", updatedTask.title, scheduleAt);
      }
      return true;
    } catch (e, st) {
      debugPrint('Update task failed: $e\n$st');
      return false;
    }
  }

  Future<bool> toggleTask(int index) async {
    try {
      final box = Hive.box<Task>('tasks');
      final task = box.getAt(index);
      if (task == null) return false;
      task.isCompleted = !task.isCompleted;
      await task.save();
      state = box.values.toList();
      return true;
    } catch (e, st) {
      debugPrint('Toggle task failed: $e\n$st');
      return false;
    }
  }

  Future<bool> deleteTask(int index) async {
    try {
      final box = Hive.box<Task>('tasks');
      await box.deleteAt(index);
      state = box.values.toList();
      return true;
    } catch (e, st) {
      debugPrint('Delete task failed: $e\n$st');
      return false;
    }
  }
}
