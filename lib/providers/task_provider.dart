import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/task.dart';
import '../services/notification_service.dart';

final taskProvider = StateNotifierProvider<TaskNotifier, List<Task>>(
  (ref) => TaskNotifier(),
);

class TaskNotifier extends StateNotifier<List<Task>> {
  late final Box _box;

  TaskNotifier() : super([]) {
    _init();
  }

  Future<void> _init() async {
    _box = Hive.box('tasksBox');
    // If box initially empty, state will be []
    state = _box.values.cast<Task>().toList();
  }

  Future<bool> addTask(Task task, {DateTime? scheduleAt}) async {
    try {
      final key = await _box.add(task);
      final stored = _box.get(key) as Task?;
      if (stored == null) return false;

      if (scheduleAt != null) {
        final payload = jsonEncode({'taskKey': key});
        final nid = await NotificationService.schedule(
          stored.title,
          stored.description.isEmpty ? stored.title : stored.description,
          scheduleAt,
          payload: payload,
        );
        if (nid != null) {
          stored.alarmDateTime = scheduleAt;
          stored.notificationId = nid;
          await _box.put(key, stored);
        }
      }

      state = _box.values.cast<Task>().toList();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateTaskByIndex(
    int index,
    Task updated, {
    DateTime? scheduleAt,
  }) async {
    try {
      final key = _box.keyAt(index) as int;
      final old = _box.getAt(index) as Task?;
      if (old != null && old.notificationId != null) {
        await NotificationService.cancel(old.notificationId!);
      }

      await _box.putAt(index, updated);

      final stored = _box.get(key) as Task?;
      if (stored != null && scheduleAt != null) {
        final payload = jsonEncode({'taskKey': key});
        final nid = await NotificationService.schedule(
          stored.title,
          stored.description.isEmpty ? stored.title : stored.description,
          scheduleAt,
          payload: payload,
        );
        if (nid != null) {
          stored.alarmDateTime = scheduleAt;
          stored.notificationId = nid;
          await _box.put(key, stored);
        }
      } else if (stored != null && scheduleAt == null) {
        stored.alarmDateTime = null;
        stored.notificationId = null;
        await _box.put(key, stored);
      }

      state = _box.values.cast<Task>().toList();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> toggleComplete(int index) async {
    try {
      final task = _box.getAt(index) as Task?;
      if (task == null) return false;
      task.isCompleted = !task.isCompleted;
      await _box.putAt(index, task);
      state = _box.values.cast<Task>().toList();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteAtIndex(int index) async {
    try {
      final task = _box.getAt(index) as Task?;
      if (task == null) return false;
      if (task.notificationId != null) {
        await NotificationService.cancel(task.notificationId!);
      }
      await _box.deleteAt(index);
      state = _box.values.cast<Task>().toList();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteMultiple(List<int> indices) async {
    try {
      final sorted = List<int>.from(indices)..sort((a, b) => b.compareTo(a));
      for (final i in sorted) {
        final t = _box.getAt(i) as Task?;
        if (t?.notificationId != null) {
          await NotificationService.cancel(t!.notificationId!);
        }
        await _box.deleteAt(i);
      }
      state = _box.values.cast<Task>().toList();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> cancelAlarmForIndex(int index) async {
    try {
      final task = _box.getAt(index) as Task?;
      if (task == null) return false;
      if (task.notificationId != null) {
        await NotificationService.cancel(task.notificationId!);
      }
      task.alarmDateTime = null;
      task.notificationId = null;
      await _box.putAt(index, task);
      state = _box.values.cast<Task>().toList();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> markDoneByKey(int key) async {
    try {
      final task = _box.get(key) as Task?;
      if (task == null) return false;
      task.isCompleted = true;
      await _box.put(key, task);
      state = _box.values.cast<Task>().toList();
      return true;
    } catch (e) {
      return false;
    }
  }
}
