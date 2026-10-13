import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'services/task_store.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final taskStore = TaskStore();
  await taskStore.load();

  runApp(LifeLoopApp(taskStore: taskStore));
}

class LifeLoopApp extends StatelessWidget {
  const LifeLoopApp({
    super.key,
    required this.taskStore,
  });

  final TaskStore taskStore;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LifeLoop',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: HomeScreen(taskStore: taskStore),
    );
  }
}
