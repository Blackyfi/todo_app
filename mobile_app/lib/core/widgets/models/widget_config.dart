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
  small,      // 2x2
  medium,     // 4x2
  large,      // 4x4
  extraLarge, // 4x5 - More vertical space
  wide,       // 5x2 - Extra wide horizontal
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
      case WidgetSize.extraLarge:
        return 'Extra Large (4x5)';
      case WidgetSize.wide:
        return 'Wide (5x2)';
    }
  }

  mat.Size get size {
    switch (this) {
      case WidgetSize.small:
        return const mat.Size(150, 150);       // 2x2 grid cells
      case WidgetSize.medium:
        return const mat.Size(300, 150);       // 4x2 grid cells
      case WidgetSize.large:
        return const mat.Size(300, 300);       // 4x4 grid cells
      case WidgetSize.extraLarge:
        return const mat.Size(300, 375);       // 4x5 grid cells
      case WidgetSize.wide:
        return const mat.Size(375, 150);       // 5x2 grid cells
    }
  }

  /// Recommended maximum tasks for each widget size
  int get recommendedMaxTasks {
    switch (this) {
      case WidgetSize.small:
        return 2;
      case WidgetSize.medium:
        return 3;
      case WidgetSize.large:
        return 6;
      case WidgetSize.extraLarge:
        return 8;
      case WidgetSize.wide:
        return 4;
    }
  }

  /// Description for each widget size
  String get description {
    switch (this) {
      case WidgetSize.small:
        return 'Compact size, shows 1-2 tasks';
      case WidgetSize.medium:
        return 'Standard size, shows 2-3 tasks';
      case WidgetSize.large:
        return 'Large size, shows 4-6 tasks';
      case WidgetSize.extraLarge:
        return 'Extra tall, shows 6-8 tasks';
      case WidgetSize.wide:
        return 'Wide format, shows 3-4 tasks';
    }
  }
}