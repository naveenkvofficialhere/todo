// test/models/task_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';
import 'package:todo_app/models/task.dart';

void main() {
  group('Task Model Tests', () {
    setUpAll(() async {
      await setUpTestHive();
      Hive.registerAdapter(TaskAdapter());
    });

    tearDownAll(() async {
      await tearDownTestHive();
    });

    group('Task Creation', () {
      test('should create a task with required parameters', () {
        final task = Task(
          title: 'Test Task',
          description: 'Test Description',
        );

        expect(task.title, equals('Test Task'));
        expect(task.description, equals('Test Description'));
        expect(task.isCompleted, isFalse);
        expect(task.alarmDateTime, isNull);
        expect(task.notificationId, isNull);
      });

      test('should create a completed task', () {
        final task = Task(
          title: 'Completed Task',
          description: 'This task is done',
          isCompleted: true,
        );

        expect(task.title, equals('Completed Task'));
        expect(task.description, equals('This task is done'));
        expect(task.isCompleted, isTrue);
      });

      test('should create a task with alarm', () {
        final alarmTime = DateTime(2024, 12, 25, 10, 30);
        final task = Task(
          title: 'Alarm Task',
          description: 'Task with alarm',
          alarmDateTime: alarmTime,
          notificationId: 123,
        );

        expect(task.title, equals('Alarm Task'));
        expect(task.alarmDateTime, equals(alarmTime));
        expect(task.notificationId, equals(123));
      });
    });

    group('Task Properties Modification', () {
      test('should allow modification of task properties', () {
        final task = Task(
          title: 'Original Title',
          description: 'Original Description',
        );

        task.title = 'Modified Title';
        task.description = 'Modified Description';
        task.isCompleted = true;

        expect(task.title, equals('Modified Title'));
        expect(task.description, equals('Modified Description'));
        expect(task.isCompleted, isTrue);
      });

      test('should allow setting and clearing alarm', () {
        final task = Task(
          title: 'Task',
          description: 'Description',
        );

        expect(task.alarmDateTime, isNull);
        expect(task.notificationId, isNull);

        final alarmTime = DateTime.now().add(Duration(hours: 1));
        task.alarmDateTime = alarmTime;
        task.notificationId = 456;

        expect(task.alarmDateTime, equals(alarmTime));
        expect(task.notificationId, equals(456));

        task.alarmDateTime = null;
        task.notificationId = null;

        expect(task.alarmDateTime, isNull);
        expect(task.notificationId, isNull);
      });
    });

    group('TaskAdapter Serialization', () {
      late Box<Task> testBox;

      setUp(() async {
        testBox = await Hive.openBox<Task>('test_tasks');
      });

      tearDown(() async {
        await testBox.clear();
        await testBox.close();
      });

      test('should serialize and deserialize basic task', () async {
        final originalTask = Task(
          title: 'Serialize Test',
          description: 'Testing serialization',
          isCompleted: false,
        );

        await testBox.put('test_key', originalTask);
        final retrievedTask = testBox.get('test_key');

        expect(retrievedTask, isNotNull);
        expect(retrievedTask!.title, equals('Serialize Test'));
        expect(retrievedTask.description, equals('Testing serialization'));
        expect(retrievedTask.isCompleted, isFalse);
        expect(retrievedTask.alarmDateTime, isNull);
        expect(retrievedTask.notificationId, isNull);
      });

      test('should serialize and deserialize completed task', () async {
        final originalTask = Task(
          title: 'Completed Task',
          description: 'Already done',
          isCompleted: true,
        );

        await testBox.put('completed_key', originalTask);
        final retrievedTask = testBox.get('completed_key');

        expect(retrievedTask, isNotNull);
        expect(retrievedTask!.title, equals('Completed Task'));
        expect(retrievedTask.description, equals('Already done'));
        expect(retrievedTask.isCompleted, isTrue);
      });

      test('should serialize and deserialize task with alarm', () async {
        final alarmTime = DateTime(2024, 12, 25, 15, 30, 0);
        final originalTask = Task(
          title: 'Alarm Task',
          description: 'Has alarm set',
          isCompleted: false,
          alarmDateTime: alarmTime,
          notificationId: 789,
        );

        await testBox.put('alarm_key', originalTask);
        final retrievedTask = testBox.get('alarm_key');

        expect(retrievedTask, isNotNull);
        expect(retrievedTask!.title, equals('Alarm Task'));
        expect(retrievedTask.description, equals('Has alarm set'));
        expect(retrievedTask.isCompleted, isFalse);
        expect(retrievedTask.alarmDateTime, equals(alarmTime));
        expect(retrievedTask.notificationId, equals(789));
      });

      test('should handle task with empty description', () async {
        final originalTask = Task(
          title: 'No Description',
          description: '',
        );

        await testBox.put('empty_desc_key', originalTask);
        final retrievedTask = testBox.get('empty_desc_key');

        expect(retrievedTask, isNotNull);
        expect(retrievedTask!.title, equals('No Description'));
        expect(retrievedTask.description, equals(''));
        expect(retrievedTask.isCompleted, isFalse);
      });

      test('should handle task with only alarm but no notification id', () async {
        final alarmTime = DateTime(2024, 12, 25, 20, 0, 0);
        final originalTask = Task(
          title: 'Alarm Only',
          description: 'Has alarm but no notification ID',
          alarmDateTime: alarmTime,
        );

        await testBox.put('alarm_only_key', originalTask);
        final retrievedTask = testBox.get('alarm_only_key');

        expect(retrievedTask, isNotNull);
        expect(retrievedTask!.title, equals('Alarm Only'));
        expect(retrievedTask.alarmDateTime, equals(alarmTime));
        expect(retrievedTask.notificationId, isNull);
      });

      test('should handle multiple tasks in box', () async {
        final task1 = Task(title: 'Task 1', description: 'First task');
        final task2 = Task(title: 'Task 2', description: 'Second task', isCompleted: true);
        final task3 = Task(
          title: 'Task 3',
          description: 'Third task',
          alarmDateTime: DateTime(2024, 12, 25, 12, 0),
          notificationId: 999,
        );

        await testBox.put('task1', task1);
        await testBox.put('task2', task2);
        await testBox.put('task3', task3);

        expect(testBox.length, equals(3));

        final retrievedTask1 = testBox.get('task1');
        final retrievedTask2 = testBox.get('task2');
        final retrievedTask3 = testBox.get('task3');

        expect(retrievedTask1!.title, equals('Task 1'));
        expect(retrievedTask1.isCompleted, isFalse);

        expect(retrievedTask2!.title, equals('Task 2'));
        expect(retrievedTask2.isCompleted, isTrue);

        expect(retrievedTask3!.title, equals('Task 3'));
        expect(retrievedTask3.alarmDateTime, isNotNull);
        expect(retrievedTask3.notificationId, equals(999));
      });
    });

    group('Edge Cases', () {
      test('should handle tasks with very long titles and descriptions', () {
        final longTitle = 'A' * 1000;
        final longDescription = 'B' * 2000;
        
        final task = Task(
          title: longTitle,
          description: longDescription,
        );

        expect(task.title, equals(longTitle));
        expect(task.description, equals(longDescription));
        expect(task.title.length, equals(1000));
        expect(task.description.length, equals(2000));
      });

      test('should handle tasks with special characters', () {
        final task = Task(
          title: '特殊字符 🚀 Title with émojis & symbols!',
          description: 'Description with\nnewlines\tand\ttabs',
        );

        expect(task.title, equals('特殊字符 🚀 Title with émojis & symbols!'));
        expect(task.description, equals('Description with\nnewlines\tand\ttabs'));
      });

      test('should handle alarm dates in different timezones', () {
        final utcTime = DateTime.utc(2024, 12, 25, 10, 30);
        final localTime = DateTime(2024, 12, 25, 10, 30);
        
        final utcTask = Task(
          title: 'UTC Task',
          description: 'Task with UTC time',
          alarmDateTime: utcTime,
        );
        
        final localTask = Task(
          title: 'Local Task',
          description: 'Task with local time',
          alarmDateTime: localTime,
        );

        expect(utcTask.alarmDateTime!.isUtc, isTrue);
        expect(localTask.alarmDateTime!.isUtc, isFalse);
      });
    });
  });
}