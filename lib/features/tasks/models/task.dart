import 'package:flutter/material.dart' as mat;

class Task {
  final int? id;
  final String title;
  final String description;
  final DateTime? dueDate;
  final bool isCompleted;
  final int? categoryId; // Changed to nullable
  final Priority priority;

  Task({
    this.id,
    required this.title,
    this.description = '',
    this.dueDate,
    this.isCompleted = false,
    this.categoryId, // Made optional
    this.priority = Priority.medium,
  });

  Task copyWith({
    int? id,
    String? title,
    String? description,
    DateTime? dueDate,
    bool? isCompleted,
    int? categoryId,
    Priority? priority,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      categoryId: categoryId, // Will be set to null if explicitly passed as null
      priority: priority ?? this.priority,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dueDate': dueDate?.millisecondsSinceEpoch,
      'isCompleted': isCompleted ? 1 : 0,
      'categoryId': categoryId,
      'priority': priority.index,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      description: map['description'] ?? '',
      dueDate: map['dueDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['dueDate'])
          : null,
      isCompleted: map['isCompleted'] == 1,
      categoryId: map['categoryId'],
      priority: Priority.values[map['priority'] ?? 1],
    );
  }
}

enum Priority {
  high,
  medium,
  low,
}

extension PriorityExtension on Priority {
  mat.Color get color {
    switch (this) {
      case Priority.high:
        return mat.Colors.red;
      case Priority.medium:
        return mat.Colors.orange;
      case Priority.low:
        return mat.Colors.green;
    }
  }

  String get label {
    switch (this) {
      case Priority.high:
        return 'High';
      case Priority.medium:
        return 'Medium';
      case Priority.low:
        return 'Low';
    }
  }
}