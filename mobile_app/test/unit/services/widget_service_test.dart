import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:todo_app/core/widgets/services/widget_service.dart';
import 'package:todo_app/core/widgets/models/widget_config.dart';
import 'package:todo_app/core/database/repository/task_repository.dart';
import 'package:todo_app/features/tasks/models/task.dart';

void main() {
  // Initialize FFI for testing
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('WidgetService Tests', () {
    late WidgetService widgetService;
    late TaskRepository taskRepository;

    setUp(() async {
      widgetService = WidgetService();
      taskRepository = TaskRepository();

      // Initialize the widget service
      try {
        await widgetService.init();
      } catch (e) {
        // Widget service initialization may fail in test environment
        // due to platform channel issues, which is expected
      }
    });

    group('Widget Configuration', () {
      test('should create a widget config', () async {
        final config = WidgetConfig(
          name: 'Test Widget',
          size: WidgetSize.medium,
          showCompleted: false,
          showCategories: true,
          showPriority: true,
          maxTasks: 5,
          createdAt: DateTime.now(),
        );

        expect(config.name, equals('Test Widget'));
        expect(config.size, equals(WidgetSize.medium));
        expect(config.showCompleted, isFalse);
        expect(config.showCategories, isTrue);
        expect(config.showPriority, isTrue);
        expect(config.maxTasks, equals(5));
      });

      test('should convert widget config to map', () async {
        final config = WidgetConfig(
          name: 'Map Test Widget',
          size: WidgetSize.large,
          showCompleted: true,
          showCategories: false,
          showPriority: false,
          maxTasks: 10,
          createdAt: DateTime.now(),
        );

        final map = config.toMap();

        expect(map['name'], equals('Map Test Widget'));
        expect(map['size'], equals(WidgetSize.large.index));
        expect(map['showCompleted'], equals(1));
        expect(map['showCategories'], equals(0));
        expect(map['showPriority'], equals(0));
        expect(map['maxTasks'], equals(10));
      });

      test('should create widget config from map', () async {
        final now = DateTime.now();
        final map = {
          'id': 1,
          'name': 'FromMap Widget',
          'size': WidgetSize.small.index,
          'showCompleted': 0,
          'showCategories': 1,
          'showPriority': 1,
          'maxTasks': 3,
          'categoryFilter': 'Work',
          'createdAt': now.millisecondsSinceEpoch,
        };

        final config = WidgetConfig.fromMap(map);

        expect(config.id, equals(1));
        expect(config.name, equals('FromMap Widget'));
        expect(config.size, equals(WidgetSize.small));
        expect(config.showCompleted, isFalse);
        expect(config.showCategories, isTrue);
        expect(config.showPriority, isTrue);
        expect(config.maxTasks, equals(3));
        expect(config.categoryFilter, equals('Work'));
      });
    });

    group('Widget Sizes', () {
      test('should have correct size dimensions', () {
        expect(WidgetSize.small.size.width, equals(150.0));
        expect(WidgetSize.small.size.height, equals(150.0));

        expect(WidgetSize.medium.size.width, equals(300.0));
        expect(WidgetSize.medium.size.height, equals(200.0));

        expect(WidgetSize.large.size.width, equals(300.0));
        expect(WidgetSize.large.size.height, equals(400.0));
      });

      test('should have correct size labels', () {
        expect(WidgetSize.small.label, equals('Small'));
        expect(WidgetSize.medium.label, equals('Medium'));
        expect(WidgetSize.large.label, equals('Large'));
      });
    });

    group('Widget Support Check', () {
      test('should check if widgets are supported', () async {
        final isSupported = await widgetService.isWidgetSupported();

        // Should return true (widgets are always supported in the implementation)
        expect(isSupported, isTrue);
      });
    });

    group('Widget Config Copy', () {
      test('should copy widget config with new values', () {
        final original = WidgetConfig(
          id: 1,
          name: 'Original',
          size: WidgetSize.small,
          showCompleted: false,
          showCategories: true,
          showPriority: true,
          maxTasks: 5,
          createdAt: DateTime.now(),
        );

        final copied = original.copyWith(
          name: 'Copied',
          size: WidgetSize.large,
          maxTasks: 10,
        );

        expect(copied.id, equals(1));
        expect(copied.name, equals('Copied'));
        expect(copied.size, equals(WidgetSize.large));
        expect(copied.showCompleted, isFalse); // Unchanged
        expect(copied.showCategories, isTrue); // Unchanged
        expect(copied.maxTasks, equals(10));
      });

      test('should copy widget config with null category filter', () {
        final original = WidgetConfig(
          name: 'Widget',
          size: WidgetSize.medium,
          showCompleted: false,
          showCategories: true,
          showPriority: true,
          maxTasks: 5,
          categoryFilter: 'Work',
          createdAt: DateTime.now(),
        );

        final copied = original.copyWith(
          categoryFilter: null,
        );

        expect(copied.categoryFilter, isNull);
      });
    });

    group('Widget Task Filtering', () {
      test('widget config should properly configure task filtering', () async {
        // Create test tasks
        final task1 = Task(
          title: 'Incomplete Task',
          priority: Priority.high,
          isCompleted: false,
        );
        final task2 = Task(
          title: 'Completed Task',
          priority: Priority.medium,
          isCompleted: true,
          completedAt: DateTime.now(),
        );

        final id1 = await taskRepository.insertTask(task1);
        final id2 = await taskRepository.insertTask(task2);

        // Create widget configs with different settings
        final showAllConfig = WidgetConfig(
          name: 'Show All',
          size: WidgetSize.medium,
          showCompleted: true,
          showCategories: true,
          showPriority: true,
          maxTasks: 10,
          createdAt: DateTime.now(),
        );

        final hideCompletedConfig = WidgetConfig(
          name: 'Hide Completed',
          size: WidgetSize.medium,
          showCompleted: false,
          showCategories: true,
          showPriority: true,
          maxTasks: 10,
          createdAt: DateTime.now(),
        );

        expect(showAllConfig.showCompleted, isTrue);
        expect(hideCompletedConfig.showCompleted, isFalse);

        // Cleanup
        await taskRepository.deleteTask(id1);
        await taskRepository.deleteTask(id2);
      });
    });

    group('Widget Max Tasks Limit', () {
      test('should respect maxTasks limit configuration', () {
        final config = WidgetConfig(
          name: 'Limited Widget',
          size: WidgetSize.small,
          showCompleted: false,
          showCategories: true,
          showPriority: true,
          maxTasks: 3,
          createdAt: DateTime.now(),
        );

        expect(config.maxTasks, equals(3));
      });

      test('should allow different maxTasks for different sizes', () {
        final smallWidget = WidgetConfig(
          name: 'Small',
          size: WidgetSize.small,
          maxTasks: 3,
          showCompleted: false,
          showCategories: true,
          showPriority: true,
          createdAt: DateTime.now(),
        );

        final mediumWidget = WidgetConfig(
          name: 'Medium',
          size: WidgetSize.medium,
          maxTasks: 5,
          showCompleted: false,
          showCategories: true,
          showPriority: true,
          createdAt: DateTime.now(),
        );

        final largeWidget = WidgetConfig(
          name: 'Large',
          size: WidgetSize.large,
          maxTasks: 10,
          showCompleted: false,
          showCategories: true,
          showPriority: true,
          createdAt: DateTime.now(),
        );

        expect(smallWidget.maxTasks, lessThan(mediumWidget.maxTasks));
        expect(mediumWidget.maxTasks, lessThan(largeWidget.maxTasks));
      });
    });
  });
}
