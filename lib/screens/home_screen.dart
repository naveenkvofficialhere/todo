import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:todo_app/widgets/empty_state.dart';

import '../models/task.dart';
import '../providers/task_provider.dart';
import '../widgets/task_tile.dart';
import '../styles/app_styles.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final Set<int> _selected = {};
  bool _selectAll = false;
  bool _selectionMode = false;
  DateTime? _lastBackPressed;

  @override
  void initState() {
    super.initState();
    _handlePendingNotification();
  }

  Future<void> _handlePendingNotification() async {
    final settings = Hive.box('settings');
    final key = settings.get('last_notification_task_key');
    if (key != null) {
      settings.delete('last_notification_task_key');
      final ok = await ref
          .read(taskProvider.notifier)
          .markDoneByKey(key as int);
      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task marked done (from notification)')),
        );
      }
    }
  }

  // Handle back button press
  Future<bool> _onWillPop() async {
    if (_selectionMode) {
      setState(() {
        _selectionMode = false;
        _selected.clear();
        _selectAll = false;
      });
      return false;
    }

    final now = DateTime.now();
    if (_lastBackPressed == null ||
        now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
      _lastBackPressed = now;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Press back again to exit'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return false;
    }

    SystemNavigator.pop(); // Exit app
    return true;
  }

  void _enterSelection(int idx) {
    setState(() {
      _selectionMode = true;
      _selected.add(idx);
      _selectAll = false;
    });
  }

  void _toggleSelect(int idx) {
    setState(() {
      if (_selected.contains(idx)) {
        _selected.remove(idx);
      } else {
        _selected.add(idx);
      }
      if (_selected.isEmpty) _selectionMode = false;
    });
  }

  void _toggleSelectAll(List<Task> tasks) {
    setState(() {
      if (_selectAll) {
        _selected.clear();
        _selectAll = false;
        _selectionMode = false;
      } else {
        _selected.clear();
        for (var i = 0; i < tasks.length; i++) {
          _selected.add(i);
        }
        _selectAll = true;
        _selectionMode = true;
      }
    });
  }

  Future<void> _deleteSelected() async {
    final indices = _selected.toList()..sort((a, b) => b.compareTo(a));
    final ok = await ref.read(taskProvider.notifier).deleteMultiple(indices);
    setState(() {
      _selected.clear();
      _selectAll = false;
      _selectionMode = false;
    });
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete some items')),
      );
    }
  }

  void _showAddEdit({Task? task, int? index}) {
    // Don't allow editing completed tasks
    if (task != null && task.isCompleted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot edit completed tasks')),
        );
      }
      return;
    }

    final titleCtrl = TextEditingController(text: task?.title ?? '');
    final descCtrl = TextEditingController(text: task?.description ?? '');
    DateTime? selected = task?.alarmDateTime;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final dateLabel = selected == null
              ? 'No alarm'
              : DateFormat('dd MMM yyyy, hh:mm a').format(selected!);
          return AlertDialog(
            title: Text(task == null ? 'Add Task' : 'Edit Task'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        enabledBorder: AppStyles.outPutDecorationCommon,
                        focusedBorder: AppStyles.outPutDecorationCommon,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Title is required';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height:8),
                    TextFormField(
                      controller: descCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        enabledBorder: AppStyles.outPutDecorationCommon,
                         focusedBorder: AppStyles.outPutDecorationCommon,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Description is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.calendar_today),
                          label: const Text('Pick Date & Time'),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: ctx,
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2100),
                              initialDate: selected ?? DateTime.now(),
                            );
                            if (picked != null && ctx.mounted) {
                              final t = await showTimePicker(
                                context: ctx,
                                initialTime: TimeOfDay.now(),
                              );
                              if (t != null) {
                                selected = DateTime(
                                  picked.year,
                                  picked.month,
                                  picked.day,
                                  t.hour,
                                  t.minute,
                                );
                                setDialogState(() {});
                              }
                            }
                          },
                        ),
                        const SizedBox(height: 8),
                        Text(dateLabel, style: AppStyles.smallText),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Alarm?'),
                        Switch(
                          value: selected != null,
                          onChanged: (v) {
                            if (!v) {
                              selected = null;
                            } else {
                              selected = DateTime.now().add(
                                const Duration(minutes: 1),
                              );
                            }
                            setDialogState(() {});
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) {
                    return; // Form validation failed
                  }

                  final title = titleCtrl.text.trim();
                  final desc = descCtrl.text.trim();

                  try {
                    final notifier = ref.read(taskProvider.notifier);
                    bool success = false;

                    if (task == null) {
                      success = await notifier.addTask(
                        Task(title: title, description: desc),
                        scheduleAt: selected,
                      );
                    } else {
                      success = await notifier.updateTaskByIndex(
                        index!,
                        Task(
                          title: title,
                          description: desc,
                          isCompleted: task.isCompleted,
                          alarmDateTime: selected,
                          notificationId: task.notificationId,
                        ),
                        scheduleAt: selected,
                      );
                    }

                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      if (success) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                task == null
                                    ? 'Task added successfully'
                                    : 'Task updated successfully',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                task == null
                                    ? 'Failed to add task'
                                    : 'Failed to update task',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    }
                  } catch (e) {
                    debugPrint('Error saving task: $e');
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('An error occurred while saving'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  }
                },
                child: Text(task == null ? 'Add Task' : 'Update Task'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTaskItem(Task task, int index, bool isCompleted) {
    final dateText = task.alarmDateTime == null
        ? null
        : DateFormat('dd MMM, hh:mm a').format(task.alarmDateTime!);

    return GestureDetector(
      onLongPress: () => _enterSelection(index),
      onTap: () {
        if (_selectionMode) {
          _toggleSelect(index);
          return;
        }
        _showAddEdit(task: task, index: index);
      },
      child: Stack(
        children: [
          Container(
            // height: 80, // Fixed height for all tiles
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: TaskTile(
              task: task,
              onToggle: () async {
                final ok = await ref
                    .read(taskProvider.notifier)
                    .toggleComplete(index);
                if (ok && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Task updated'),
                      action: SnackBarAction(
                        label: 'Undo',
                        onPressed: () async {
                          await ref
                              .read(taskProvider.notifier)
                              .toggleComplete(index);
                        },
                      ),
                    ),
                  );
                }
              },
              onEdit: isCompleted
                  ? null // Disable edit for completed tasks
                  : () => _showAddEdit(task: task, index: index),
              onDelete: () async {
                final ok = await ref
                    .read(taskProvider.notifier)
                    .deleteAtIndex(index);
                if (!ok && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Delete failed')),
                  );
                }
              },
              dateText: dateText,
              // isFixedHeight: true, // Pass this to TaskTile to handle clipping
            ),
          ),
          if (_selectionMode)
            Positioned(
              left: 12,
              top: 8,
              child: Checkbox(
                value: _selected.contains(index),
                onChanged: (_) => _toggleSelect(index),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(taskProvider);

    // Partition tasks into pending and completed
    final pending = tasks.where((t) => !t.isCompleted).toList();
    final completed = tasks.where((t) => t.isCompleted).toList();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          await _onWillPop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: _selectionMode
              ? Text('${_selected.length} selected')
              : const Text('To-Do'),
          automaticallyImplyLeading: false, // Remove default back button
          actions: _selectionMode
              ? [
                  IconButton(
                    icon: const Text("Select all"),
                    onPressed: () => _toggleSelectAll(tasks),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: _deleteSelected,
                  ),
                ]
              : [],
        ),
        body: tasks.isEmpty
            ? const EmptyState()
            : SingleChildScrollView(
                child: Column(
                  children: [
                    if (pending.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 16,
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Pending',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                      ),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: pending.length,
                        itemBuilder: (context, i) {
                          final t = pending[i];
                          final idx = tasks.indexOf(t);
                          return _buildTaskItem(t, idx, false);
                        },
                      ),
                    ],
                    if (completed.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 16,
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Completed',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ),
                      ),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: completed.length,
                        itemBuilder: (context, i) {
                          final t = completed[i];
                          final idx = tasks.indexOf(t);
                          return _buildTaskItem(t, idx, true);
                        },
                      ),
                    ],
                    const SizedBox(height: 80), // padding for FAB
                  ],
                ),
              ),
        floatingActionButton: !_selectionMode
            ? FloatingActionButton(
                onPressed: () => _showAddEdit(),
                child: const Icon(Icons.add),
              )
            : FloatingActionButton(
                onPressed: () {
                  setState(() {
                    _selectionMode = false;
                    _selected.clear();
                    _selectAll = false;
                  });
                },
                child: const Icon(Icons.close),
              ),
      ),
    );
  }
}
