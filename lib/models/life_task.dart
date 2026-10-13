import 'package:flutter/material.dart';

enum TaskCategory {
  home,
  health,
  vehicle,
  documents,
  personal,
}

extension TaskCategoryDetails on TaskCategory {
  String get label {
    switch (this) {
      case TaskCategory.home:
        return 'Home';
      case TaskCategory.health:
        return 'Health';
      case TaskCategory.vehicle:
        return 'Vehicle';
      case TaskCategory.documents:
        return 'Documents';
      case TaskCategory.personal:
        return 'Personal';
    }
  }

  IconData get icon {
    switch (this) {
      case TaskCategory.home:
        return Icons.home_rounded;
      case TaskCategory.health:
        return Icons.favorite_rounded;
      case TaskCategory.vehicle:
        return Icons.directions_car_rounded;
      case TaskCategory.documents:
        return Icons.description_rounded;
      case TaskCategory.personal:
        return Icons.spa_rounded;
    }
  }

  Color get color {
    switch (this) {
      case TaskCategory.home:
        return const Color(0xFF287D72);
      case TaskCategory.health:
        return const Color(0xFFD66B54);
      case TaskCategory.vehicle:
        return const Color(0xFF5278B8);
      case TaskCategory.documents:
        return const Color(0xFF9872B5);
      case TaskCategory.personal:
        return const Color(0xFFB58A36);
    }
  }
}

class LifeTask {
  LifeTask({
    required this.id,
    required this.title,
    required this.note,
    required this.category,
    required this.dueDate,
    required this.repeatEveryDays,
    this.isCompleted = false,
    this.completedAt,
  });

  final String id;
  final String title;
  final String note;
  final TaskCategory category;
  final DateTime dueDate;
  final int repeatEveryDays;
  bool isCompleted;
  DateTime? completedAt;

  bool get isOverdue =>
      !isCompleted && _dateOnly(dueDate).isBefore(_dateOnly(DateTime.now()));

  bool get isDueToday =>
      !isCompleted && _dateOnly(dueDate) == _dateOnly(DateTime.now());

  bool get isDueSoon {
    final today = _dateOnly(DateTime.now());
    final due = _dateOnly(dueDate);
    return !isCompleted &&
        !due.isBefore(today) &&
        due.difference(today).inDays <= 7;
  }

  void markComplete() {
    isCompleted = true;
    completedAt = DateTime.now();
  }

  void reopen() {
    isCompleted = false;
    completedAt = null;
  }

  LifeTask copyWith({
    String? title,
    String? note,
    TaskCategory? category,
    DateTime? dueDate,
    int? repeatEveryDays,
  }) {
    return LifeTask(
      id: id,
      title: title ?? this.title,
      note: note ?? this.note,
      category: category ?? this.category,
      dueDate: dueDate ?? this.dueDate,
      repeatEveryDays: repeatEveryDays ?? this.repeatEveryDays,
      isCompleted: isCompleted,
      completedAt: completedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'note': note,
        'category': category.name,
        'dueDate': dueDate.toIso8601String(),
        'repeatEveryDays': repeatEveryDays,
        'isCompleted': isCompleted,
        'completedAt': completedAt?.toIso8601String(),
      };

  factory LifeTask.fromJson(Map<String, dynamic> json) {
    return LifeTask(
      id: json['id'] as String,
      title: json['title'] as String,
      note: json['note'] as String? ?? '',
      category: TaskCategory.values.firstWhere(
        (value) => value.name == json['category'],
        orElse: () => TaskCategory.personal,
      ),
      dueDate: DateTime.parse(json['dueDate'] as String),
      repeatEveryDays: json['repeatEveryDays'] as int? ?? 0,
      isCompleted: json['isCompleted'] as bool? ?? false,
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
    );
  }
}

DateTime _dateOnly(DateTime date) =>
    DateTime(date.year, date.month, date.day);
