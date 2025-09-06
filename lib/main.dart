import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/task.dart';
import 'services/notification_service.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(TaskAdapter());
  await Hive.openBox('tasksBox');
  await Hive.openBox('settings');

  await NotificationService.init(
    onDidReceiveNotificationResponse: (payload) {
      if (payload == null) return;
      try {
        final Map<String, dynamic> map = jsonDecode(payload);
        final key = map['taskKey'];
        if (key != null) {
          final settings = Hive.box('settings');
          settings.put('last_notification_task_key', key);
        }
      } catch (e, st) {
        debugPrint('notif payload parse error: $e\n$st');
      }
    },
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'To-Do App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system,
      home: const SplashScreen(),
    );
  }
}
