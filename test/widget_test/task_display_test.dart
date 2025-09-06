// test/widgets/home_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';
import 'package:todo_app/models/task.dart';
import 'package:todo_app/providers/task_provider.dart';
import 'package:todo_app/screens/home_screen.dart';
import 'package:todo_app/widgets/empty_state.dart';
import 'package:todo_app/widgets/task_tile.dart';

// Create a test provider that overrides the original
final testTaskProvider = StateNotifierProvider<TaskNotifier, List<Task>>((ref) {
  return TaskNotifier();
});

void main() {
  group('Home Screen Widget Tests', () {
    late Box tasksBox;
    late Box settingsBox;

    setUpAll(() async {
      await setUpTestHive();
      Hive.registerAdapter(TaskAdapter());
    });

    tearDownAll(() async {
      await tearDownTestHive();
    });

    setUp(() async {
      tasksBox = await Hive.openBox('tasksBox');
      settingsBox = await Hive.openBox('settings');
    });

    tearDown(() async {
      await tasksBox.clear();
      await settingsBox.clear();
      await tasksBox.close();
      await settingsBox.close();
    });

    Future<Widget> createTestWidget({List<Task>? initialTasks}) async {
      // Add initial tasks to Hive if provided
      if (initialTasks != null) {
        for (final task in initialTasks) {
          await tasksBox.add(task);
        }
      }

      return ProviderScope(child: MaterialApp(home: HomeScreen()));
    }

    group('Empty State', () {
      testWidgets('should display empty state when no tasks exist', (
        tester,
      ) async {
        final widget = await createTestWidget();
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        expect(find.byType(EmptyState), findsOneWidget);
        expect(
          find.text('✨ No tasks yet.\nTap + to create your first to-do!'),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.add), findsOneWidget);
      });

      testWidgets('should show floating action button in empty state', (
        tester,
      ) async {
        final widget = await createTestWidget();
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        final fab = find.byType(FloatingActionButton);
        expect(fab, findsOneWidget);
        expect(find.byIcon(Icons.add), findsOneWidget);
      });
    });

    group('Task Display', () {
      testWidgets('should display single task correctly', (tester) async {
        final tasks = [
          Task(
            title: 'Test Task',
            description: 'Test Description',
            isCompleted: false,
          ),
        ];

        final widget = await createTestWidget(initialTasks: tasks);
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        expect(find.text('Test Task'), findsOneWidget);
        expect(find.text('Test Description'), findsOneWidget);
        expect(find.byType(TaskTile), findsOneWidget);
        expect(find.text('Pending'), findsOneWidget);
      });

      testWidgets('should display multiple tasks with correct sections', (
        tester,
      ) async {
        final tasks = [
          Task(
            title: 'Pending Task 1',
            description: 'Description 1',
            isCompleted: false,
          ),
          Task(
            title: 'Pending Task 2',
            description: 'Description 2',
            isCompleted: false,
          ),
          Task(
            title: 'Completed Task 1',
            description: 'Description 3',
            isCompleted: true,
          ),
          Task(
            title: 'Completed Task 2',
            description: 'Description 4',
            isCompleted: true,
          ),
        ];

        final widget = await createTestWidget(initialTasks: tasks);
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        // Check section headers
        expect(find.text('Pending'), findsOneWidget);
        expect(find.text('Completed'), findsOneWidget);

        // Check pending tasks
        expect(find.text('Pending Task 1'), findsOneWidget);
        expect(find.text('Pending Task 2'), findsOneWidget);

        // Check completed tasks
        expect(find.text('Completed Task 1'), findsOneWidget);
        expect(find.text('Completed Task 2'), findsOneWidget);

        // Check total number of task tiles
        expect(find.byType(TaskTile), findsNWidgets(4));
      });

      testWidgets(
        'should display only pending section when no completed tasks',
        (tester) async {
          final tasks = [
            Task(
              title: 'Only Pending',
              description: 'Description',
              isCompleted: false,
            ),
          ];

          final widget = await createTestWidget(initialTasks: tasks);
          await tester.pumpWidget(widget);
          await tester.pumpAndSettle();

          expect(find.text('Pending'), findsOneWidget);
          expect(find.text('Completed'), findsNothing);
          expect(find.text('Only Pending'), findsOneWidget);
        },
      );

      testWidgets(
        'should display only completed section when no pending tasks',
        (tester) async {
          final tasks = [
            Task(
              title: 'Only Completed',
              description: 'Description',
              isCompleted: true,
            ),
          ];

          final widget = await createTestWidget(initialTasks: tasks);
          await tester.pumpWidget(widget);
          await tester.pumpAndSettle();

          expect(find.text('Pending'), findsNothing);
          expect(find.text('Completed'), findsOneWidget);
          expect(find.text('Only Completed'), findsOneWidget);
        },
      );
    });

    group('Task Interactions', () {
      testWidgets('should show task dialog when FAB is tapped', (tester) async {
        final widget = await createTestWidget();
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();

        expect(find.text('Add Task'), findsOneWidget);
        expect(find.text('Title'), findsOneWidget);
        expect(find.text('Description'), findsOneWidget);
        expect(find.text('Pick Date & Time'), findsOneWidget);
      });

      testWidgets('should handle task completion toggle', (tester) async {
        final tasks = [
          Task(
            title: 'Toggle Task',
            description: 'Description',
            isCompleted: false,
          ),
        ];

        final widget = await createTestWidget(initialTasks: tasks);
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        // Find the checkbox/toggle button
        final toggleButton = find.byIcon(Icons.radio_button_unchecked);
        expect(toggleButton, findsOneWidget);

        await tester.tap(toggleButton);
        await tester.pumpAndSettle();

        // Should show snackbar with undo option
        expect(find.text('Task updated'), findsOneWidget);
        expect(find.text('Undo'), findsOneWidget);
      });

      testWidgets('should show edit dialog when task is tapped', (
        tester,
      ) async {
        final tasks = [
          Task(
            title: 'Edit Task',
            description: 'Edit Description',
            isCompleted: false,
          ),
        ];

        final widget = await createTestWidget(initialTasks: tasks);
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        // Tap on the task tile (but not on buttons)
        await tester.tap(find.text('Edit Task'));
        await tester.pumpAndSettle();

        expect(
          find.text('Edit Task'),
          findsNWidgets(2),
        ); // One in list, one in dialog
        expect(find.textContaining('Title'), findsOneWidget);
      });

      testWidgets('should handle delete button tap', (tester) async {
        final tasks = [
          Task(
            title: 'Delete Task',
            description: 'To be deleted',
            isCompleted: false,
          ),
        ];

        final widget = await createTestWidget(initialTasks: tasks);
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        // Find and tap the delete button
        final deleteButton = find.byIcon(Icons.delete);
        expect(deleteButton, findsOneWidget);

        await tester.tap(deleteButton);
        await tester.pumpAndSettle();

        // Should show empty state after deletion
        expect(find.byType(EmptyState), findsOneWidget);
      });
    });

    group('Selection Mode', () {
      testWidgets('should enter selection mode on long press', (tester) async {
        final tasks = [
          Task(
            title: 'Select Task',
            description: 'Description',
            isCompleted: false,
          ),
        ];

        final widget = await createTestWidget(initialTasks: tasks);
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        // Long press on task
        await tester.longPress(find.text('Select Task'));
        await tester.pumpAndSettle();

        // Should show selection UI
        expect(find.text('1 selected'), findsOneWidget);
        expect(find.byType(Checkbox), findsOneWidget);
        expect(
          find.byIcon(Icons.delete),
          findsOneWidget,
        ); // Delete button in app bar
      });

      testWidgets('should show close FAB in selection mode', (tester) async {
        final tasks = [
          Task(
            title: 'Select Task',
            description: 'Description',
            isCompleted: false,
          ),
        ];

        final widget = await createTestWidget(initialTasks: tasks);
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        await tester.longPress(find.text('Select Task'));
        await tester.pumpAndSettle();

        // FAB should change to close icon
        expect(find.byIcon(Icons.close), findsOneWidget);
        expect(find.byIcon(Icons.add), findsNothing);
      });

      testWidgets('should exit selection mode when close FAB is tapped', (
        tester,
      ) async {
        final tasks = [
          Task(
            title: 'Select Task',
            description: 'Description',
            isCompleted: false,
          ),
        ];

        final widget = await createTestWidget(initialTasks: tasks);
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        // Enter selection mode
        await tester.longPress(find.text('Select Task'));
        await tester.pumpAndSettle();
        expect(find.text('1 selected'), findsOneWidget);

        // Tap close FAB
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        // Should exit selection mode
        expect(find.text('To-Do'), findsOneWidget); // Back to normal title
        expect(find.byIcon(Icons.add), findsOneWidget); // Back to add FAB
        expect(find.byType(Checkbox), findsNothing);
      });
    });

    group('App Bar', () {
      testWidgets('should show correct app bar title in normal mode', (
        tester,
      ) async {
        final widget = await createTestWidget();
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        expect(find.text('To-Do'), findsOneWidget);
        expect(find.byType(AppBar), findsOneWidget);
      });

      testWidgets('should not show back button', (tester) async {
        final widget = await createTestWidget();
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        // Should not have automatic back button
        expect(find.byTooltip('Back'), findsNothing);
      });
    });

    group('Task with Alarm', () {
      testWidgets('should display task with alarm time', (tester) async {
        final alarmTime = DateTime(2024, 12, 25, 14, 30);
        final tasks = [
          Task(
            title: 'Alarm Task',
            description: 'Has alarm',
            isCompleted: false,
            alarmDateTime: alarmTime,
          ),
        ];

        final widget = await createTestWidget(initialTasks: tasks);
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        expect(find.text('Alarm Task'), findsOneWidget);
        expect(find.text('Has alarm'), findsOneWidget);
        // Check for alarm icon/text (assuming your TaskTile shows it)
        expect(find.textContaining('⏰'), findsOneWidget);
      });
    });

    group('Scrolling', () {
      testWidgets('should be scrollable with many tasks', (tester) async {
        // Create many tasks to test scrolling
        final tasks = List.generate(
          20,
          (index) => Task(
            title: 'Task ${index + 1}',
            description: 'Description ${index + 1}',
            isCompleted: index % 2 == 0, // Alternate completed status
          ),
        );

        final widget = await createTestWidget(initialTasks: tasks);
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        // Should find the first task
        expect(find.text('Task 1'), findsOneWidget);

        // Scroll down to find later tasks
        await tester.drag(find.byType(SingleChildScrollView), Offset(0, -2000));
        await tester.pumpAndSettle();

        // Should be able to scroll and find later tasks
        expect(find.byType(TaskTile), findsWidgets);
      });
    });

    group('Edge Cases', () {
      testWidgets('should handle task with empty description', (tester) async {
        final tasks = [
          Task(
            title: 'No Description Task',
            description: '',
            isCompleted: false,
          ),
        ];

        final widget = await createTestWidget(initialTasks: tasks);
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        expect(find.text('No Description Task'), findsOneWidget);
        // Empty description should not cause issues
        expect(find.byType(TaskTile), findsOneWidget);
      });

      testWidgets('should handle very long task titles', (tester) async {
        final longTitle =
            'This is a very long task title that might cause layout issues if not handled properly';
        final tasks = [
          Task(
            title: longTitle,
            description: 'Description',
            isCompleted: false,
          ),
        ];

        final widget = await createTestWidget(initialTasks: tasks);
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        expect(
          find.textContaining('This is a very long task title'),
          findsOneWidget,
        );
        expect(find.byType(TaskTile), findsOneWidget);
      });
    });

    group('Form Validation', () {
      testWidgets('should validate required fields in add task dialog', (
        tester,
      ) async {
        final widget = await createTestWidget();
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        // Open add task dialog
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();

        // Try to save without filling required fields
        await tester.tap(find.text('Add Task'));
        await tester.pumpAndSettle();

        // Should show validation errors
        expect(find.text('Title is required'), findsOneWidget);
        expect(find.text('Description is required'), findsOneWidget);
      });

      testWidgets('should successfully add task with valid data', (
        tester,
      ) async {
        final widget = await createTestWidget();
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        // Open add task dialog
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();

        // Fill in the form
        await tester.enterText(
          find.byType(TextFormField).first,
          'New Task Title',
        );
        await tester.enterText(
          find.byType(TextFormField).last,
          'New Task Description',
        );
        await tester.pumpAndSettle();

        // Save the task
        await tester.tap(find.text('Add Task'));
        await tester.pumpAndSettle();

        // Should show success message and new task
        expect(find.text('Task added successfully'), findsOneWidget);
        expect(find.text('New Task Title'), findsOneWidget);
        expect(find.text('New Task Description'), findsOneWidget);
      });
    });
  });
}
