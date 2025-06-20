import 'package:flutter/material.dart' as mat;

class WidgetConfig {
  final int? id;
  final String name;
  final WidgetSize size;
  final bool showCompleted;
  final bool showCategories;
  final bool showPriority;
  final String? categoryFilter; // null means all categories
  final int maxTasks;
  final DateTime? createdAt;

  WidgetConfig({
    this.id,
    required this.name,
    this.size = WidgetSize.medium,
    this.showCompleted = false,
    this.showCategories = true,
    this.showPriority = true,
    this.categoryFilter,
    this.maxTasks = 3, // Reduced default for widget stability
    this.createdAt,
  });

  WidgetConfig copyWith({
    int? id,
    String? name,
    WidgetSize? size,
    bool? showCompleted,
    bool? showCategories,
    bool? showPriority,
    String? categoryFilter,
    int? maxTasks,
    DateTime? createdAt,
  }) {
    return WidgetConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      size: size ?? this.size,
      showCompleted: showCompleted ?? this.showCompleted,
      showCategories: showCategories ?? this.showCategories,
      showPriority: showPriority ?? this.showPriority,
      categoryFilter: categoryFilter ?? this.categoryFilter,
      maxTasks: maxTasks ?? this.maxTasks,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'size': size.index,
      'showCompleted': showCompleted ? 1 : 0,
      'showCategories': showCategories ? 1 : 0,
      'showPriority': showPriority ? 1 : 0,
      'categoryFilter': categoryFilter,
      'maxTasks': maxTasks,
      'createdAt': createdAt?.millisecondsSinceEpoch,
    };
  }

  factory WidgetConfig.fromMap(Map<String, dynamic> map) {
    return WidgetConfig(
      id: map['id'],
      name: map['name'],
      size: WidgetSize.values[map['size'] ?? 1],
      showCompleted: map['showCompleted'] == 1,
      showCategories: map['showCategories'] == 1,
      showPriority: map['showPriority'] == 1,
      categoryFilter: map['categoryFilter'],
      maxTasks: map['maxTasks'] ?? 5,
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : null,
    );
  }
}

enum WidgetSize {
  small,
  medium,
  large,
}

extension WidgetSizeExtension on WidgetSize {
  String get label {
    switch (this) {
      case WidgetSize.small:
        return 'Small (2x2)';
      case WidgetSize.medium:
        return 'Medium (4x2)';
      case WidgetSize.large:
        return 'Large (4x4)';
    }
  }

  mat.Size get size {
    switch (this) {
      case WidgetSize.small:
        return const mat.Size(150, 150);
      case WidgetSize.medium:
        return const mat.Size(300, 150);
      case WidgetSize.large:
        return const mat.Size(300, 300);
    }
  }
}