import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/life_task.dart';

class TaskStore extends ChangeNotifier {
  static const _storageKey = 'lifeloop_tasks_v1';

  final List<LifeTask> _tasks = [];

  List<LifeTask> get tasks => List.unmodifiable(_tasks);

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_storageKey);

    if (raw != null) {
      try {
        final decoded = jsonDecode(raw) as List<dynamic>;
        _tasks
          ..clear()
          ..addAll(
            decoded.map(
              (item) => LifeTask.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            ),
          );
      } catch (_) {
        _tasks
          ..clear()
          ..addAll(_starterTasks());
      }
    } else {
      _tasks.addAll(_starterTasks());
    }

    await _save();
    notifyListeners();
  }

  Future<void> add(LifeTask task) async {
    _tasks.insert(0, task);
    await _save();
    notifyListeners();
  }

  Future<void> update(LifeTask updatedTask) async {
    final index = _tasks.indexWhere((task) => task.id == updatedTask.id);
    if (index == -1) return;

    _tasks[index] = updatedTask;
    await _save();
    notifyListeners();
  }

  Future<void> delete(String id) async {
    _tasks.removeWhere((task) => task.id == id);
    await _save();
    notifyListeners();
  }

  Future<void> toggleComplete(LifeTask task) async {
    if (task.isCompleted) {
      task.reopen();
    } else if (task.repeatEveryDays > 0) {
      final nextDate = task.dueDate.add(
        Duration(days: task.repeatEveryDays),
      );
      final nextTask = task.copyWith(dueDate: nextDate);
      final index = _tasks.indexWhere((item) => item.id == task.id);
      if (index != -1) _tasks[index] = nextTask;
    } else {
      task.markComplete();
    }

    await _save();
    notifyListeners();
  }

  Future<void> _save() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _storageKey,
      jsonEncode(_tasks.map((task) => task.toJson()).toList()),
    );
  }

  List<LifeTask> _starterTasks() {
    final today = DateTime.now();
    DateTime at(int offset) =>
        DateTime(today.year, today.month, today.day).add(Duration(days: offset));

    return [
      LifeTask(
        id: 'starter-smoke-alarm',
        title: 'Test smoke alarms',
        note: 'Press the test button and check every floor.',
        category: TaskCategory.home,
        dueDate: at(0),
        repeatEveryDays: 30,
      ),
      LifeTask(
        id: 'starter-water-filter',
        title: 'Replace water filter',
        note: 'Check the filter model before buying a replacement.',
        category: TaskCategory.home,
        dueDate: at(2),
        repeatEveryDays: 90,
      ),
      LifeTask(
        id: 'starter-first-aid',
        title: 'Check first-aid kit',
        note: 'Restock plasters and review expiry dates.',
        category: TaskCategory.health,
        dueDate: at(5),
        repeatEveryDays: 90,
      ),
      LifeTask(
        id: 'starter-documents',
        title: 'Review document expiry dates',
        note: 'Check IDs, permits, and other important paperwork.',
        category: TaskCategory.documents,
        dueDate: at(14),
        repeatEveryDays: 0,
      ),
      LifeTask(
        id: 'starter-tire',
        title: 'Check tire pressure',
        note: 'Use the pressure listed in the vehicle manual or door label.',
        category: TaskCategory.vehicle,
        dueDate: at(-2),
        repeatEveryDays: 30,
      ),
    ];
  }
}
