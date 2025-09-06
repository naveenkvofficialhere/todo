// lib/models/task.dart
import 'package:hive/hive.dart';

// part 'task.g.dart'; //

class Task {
  String title;
  String description;
  bool isCompleted;
  DateTime? alarmDateTime;
  int? notificationId;

  Task({
    required this.title,
    required this.description,
    this.isCompleted = false,
    this.alarmDateTime,
    this.notificationId,
  });
}

class TaskAdapter extends TypeAdapter<Task> {
  @override
  final int typeId = 0;

  @override
  Task read(BinaryReader reader) {
    final title = reader.readString();
    final description = reader.readString();
    final isCompleted = reader.readBool();
    final hasAlarm = reader.readBool();
    DateTime? alarm;
    if (hasAlarm) {
      final millis = reader.readInt();
      alarm = DateTime.fromMillisecondsSinceEpoch(millis);
    }
    final hasNotifId = reader.readBool();
    int? nid;
    if (hasNotifId) {
      nid = reader.readInt();
    }
    return Task(
      title: title,
      description: description,
      isCompleted: isCompleted,
      alarmDateTime: alarm,
      notificationId: nid,
    );
  }

  @override
  void write(BinaryWriter writer, Task obj) {
    writer.writeString(obj.title);
    writer.writeString(obj.description);
    writer.writeBool(obj.isCompleted);
    if (obj.alarmDateTime != null) {
      writer.writeBool(true);
      writer.writeInt(obj.alarmDateTime!.millisecondsSinceEpoch);
    } else {
      writer.writeBool(false);
    }
    if (obj.notificationId != null) {
      writer.writeBool(true);
      writer.writeInt(obj.notificationId!);
    } else {
      writer.writeBool(false);
    }
  }
}
