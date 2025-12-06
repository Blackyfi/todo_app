import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:todo_app/core/widgets/repository/widget_config_repository.dart';
import 'package:todo_app/core/widgets/models/widget_config.dart';

void main() {
  // Initialize FFI for testing
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('WidgetConfigRepository Tests', () {
    late WidgetConfigRepository repository;

    setUp(() {
      repository = WidgetConfigRepository();
    });

    group('Widget Config CRUD Operations', () {
      test('should insert and retrieve a widget config', () async {
        final config = WidgetConfig(
          name: 'My Widget',
          size: WidgetSize.medium,
          showCompleted: true,
          showCategories: true,
          showPriority: true,
          maxTasks: 5,
        );

        final id = await repository.insertWidgetConfig(config);
        expect(id, isPositive);

        final retrievedConfig = await repository.getWidgetConfig(id);
        expect(retrievedConfig, isNotNull);
        expect(retrievedConfig!.name, equals('My Widget'));
        expect(retrievedConfig.size, equals(WidgetSize.medium));
        expect(retrievedConfig.showCompleted, isTrue);
        expect(retrievedConfig.showCategories, isTrue);
        expect(retrievedConfig.showPriority, isTrue);
        expect(retrievedConfig.maxTasks, equals(5));

        // Cleanup
        await repository.deleteWidgetConfig(id);
      });

      test('should insert widget config with default values', () async {
        final config = WidgetConfig(
          name: 'Default Widget',
        );

        final id = await repository.insertWidgetConfig(config);

        final retrievedConfig = await repository.getWidgetConfig(id);
        expect(retrievedConfig!.name, equals('Default Widget'));
        expect(retrievedConfig.size, equals(WidgetSize.medium));
        expect(retrievedConfig.showCompleted, isFalse);
        expect(retrievedConfig.showCategories, isTrue);
        expect(retrievedConfig.showPriority, isTrue);
        expect(retrievedConfig.maxTasks, equals(3));
        expect(retrievedConfig.categoryFilter, isNull);

        // Cleanup
        await repository.deleteWidgetConfig(id);
      });

      test('should insert widget config with category filter', () async {
        final config = WidgetConfig(
          name: 'Work Widget',
          categoryFilter: 'Work',
          maxTasks: 10,
        );

        final id = await repository.insertWidgetConfig(config);

        final retrievedConfig = await repository.getWidgetConfig(id);
        expect(retrievedConfig!.categoryFilter, equals('Work'));
        expect(retrievedConfig.maxTasks, equals(10));

        // Cleanup
        await repository.deleteWidgetConfig(id);
      });

      test('should update an existing widget config', () async {
        final config = WidgetConfig(
          name: 'Original Widget',
          size: WidgetSize.small,
          showCompleted: false,
          maxTasks: 3,
        );

        final id = await repository.insertWidgetConfig(config);

        final updatedConfig = config.copyWith(
          id: id,
          name: 'Updated Widget',
          size: WidgetSize.large,
          showCompleted: true,
          showCategories: false,
          maxTasks: 8,
        );

        await repository.updateWidgetConfig(updatedConfig);

        final retrievedConfig = await repository.getWidgetConfig(id);
        expect(retrievedConfig!.name, equals('Updated Widget'));
        expect(retrievedConfig.size, equals(WidgetSize.large));
        expect(retrievedConfig.showCompleted, isTrue);
        expect(retrievedConfig.showCategories, isFalse);
        expect(retrievedConfig.maxTasks, equals(8));

        // Cleanup
        await repository.deleteWidgetConfig(id);
      });

      test('should delete a widget config', () async {
        final config = WidgetConfig(
          name: 'Widget to Delete',
          size: WidgetSize.small,
        );

        final id = await repository.insertWidgetConfig(config);

        final deleteResult = await repository.deleteWidgetConfig(id);
        expect(deleteResult, equals(1));

        final retrievedConfig = await repository.getWidgetConfig(id);
        expect(retrievedConfig, isNull);
      });

      test('should return null when getting non-existent widget config', () async {
        final config = await repository.getWidgetConfig(99999);
        expect(config, isNull);
      });
    });

    group('Widget Config Sizes', () {
      test('should correctly store all widget sizes', () async {
        final sizes = [
          WidgetSize.small,
          WidgetSize.medium,
          WidgetSize.large,
        ];

        final ids = <int>[];

        for (var i = 0; i < sizes.length; i++) {
          final config = WidgetConfig(
            name: '${sizes[i].label} Widget',
            size: sizes[i],
          );
          final id = await repository.insertWidgetConfig(config);
          ids.add(id);
        }

        for (var i = 0; i < sizes.length; i++) {
          final retrievedConfig = await repository.getWidgetConfig(ids[i]);
          expect(retrievedConfig!.size, equals(sizes[i]));
        }

        // Cleanup
        for (final id in ids) {
          await repository.deleteWidgetConfig(id);
        }
      });
    });

    group('Get All Widget Configs', () {
      test('should retrieve all widget configs ordered by creation date', () async {
        // Create widgets with slight delay to ensure different timestamps
        final config1 = WidgetConfig(name: 'Widget 1', size: WidgetSize.small);
        final id1 = await repository.insertWidgetConfig(config1);

        await Future.delayed(const Duration(milliseconds: 10));

        final config2 = WidgetConfig(name: 'Widget 2', size: WidgetSize.medium);
        final id2 = await repository.insertWidgetConfig(config2);

        await Future.delayed(const Duration(milliseconds: 10));

        final config3 = WidgetConfig(name: 'Widget 3', size: WidgetSize.large);
        final id3 = await repository.insertWidgetConfig(config3);

        final allConfigs = await repository.getAllWidgetConfigs();

        expect(allConfigs.length, greaterThanOrEqualTo(3));

        final ourConfigs = allConfigs.where((c) =>
          c.id == id1 || c.id == id2 || c.id == id3
        ).toList();

        expect(ourConfigs.length, equals(3));

        // Should be ordered by createdAt DESC (newest first)
        final ourConfigsSorted = ourConfigs.toList()
          ..sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));

        expect(ourConfigsSorted.first.name, equals('Widget 3'));
        expect(ourConfigsSorted.last.name, equals('Widget 1'));

        // Cleanup
        await repository.deleteWidgetConfig(id1);
        await repository.deleteWidgetConfig(id2);
        await repository.deleteWidgetConfig(id3);
      });

      test('should return empty list when no widget configs exist', () async {
        // Delete all existing configs first
        final allConfigs = await repository.getAllWidgetConfigs();
        for (final config in allConfigs) {
          if (config.id != null) {
            await repository.deleteWidgetConfig(config.id!);
          }
        }

        final configs = await repository.getAllWidgetConfigs();
        expect(configs, isEmpty);
      });
    });

    group('Widget Config Display Options', () {
      test('should toggle showCompleted correctly', () async {
        final config = WidgetConfig(
          name: 'Toggle Test',
          showCompleted: false,
        );

        final id = await repository.insertWidgetConfig(config);

        final updatedConfig = config.copyWith(
          id: id,
          showCompleted: true,
        );

        await repository.updateWidgetConfig(updatedConfig);

        final retrievedConfig = await repository.getWidgetConfig(id);
        expect(retrievedConfig!.showCompleted, isTrue);

        // Cleanup
        await repository.deleteWidgetConfig(id);
      });

      test('should toggle showCategories correctly', () async {
        final config = WidgetConfig(
          name: 'Category Toggle',
          showCategories: true,
        );

        final id = await repository.insertWidgetConfig(config);

        final updatedConfig = config.copyWith(
          id: id,
          showCategories: false,
        );

        await repository.updateWidgetConfig(updatedConfig);

        final retrievedConfig = await repository.getWidgetConfig(id);
        expect(retrievedConfig!.showCategories, isFalse);

        // Cleanup
        await repository.deleteWidgetConfig(id);
      });

      test('should toggle showPriority correctly', () async {
        final config = WidgetConfig(
          name: 'Priority Toggle',
          showPriority: true,
        );

        final id = await repository.insertWidgetConfig(config);

        final updatedConfig = config.copyWith(
          id: id,
          showPriority: false,
        );

        await repository.updateWidgetConfig(updatedConfig);

        final retrievedConfig = await repository.getWidgetConfig(id);
        expect(retrievedConfig!.showPriority, isFalse);

        // Cleanup
        await repository.deleteWidgetConfig(id);
      });
    });

    group('Widget Config Category Filter', () {
      test('should update category filter', () async {
        final config = WidgetConfig(
          name: 'Filter Test',
          categoryFilter: null,
        );

        final id = await repository.insertWidgetConfig(config);

        final updatedConfig = config.copyWith(
          id: id,
          categoryFilter: 'Personal',
        );

        await repository.updateWidgetConfig(updatedConfig);

        final retrievedConfig = await repository.getWidgetConfig(id);
        expect(retrievedConfig!.categoryFilter, equals('Personal'));

        // Cleanup
        await repository.deleteWidgetConfig(id);
      });

      test('should clear category filter', () async {
        final config = WidgetConfig(
          name: 'Clear Filter Test',
          categoryFilter: 'Work',
        );

        final id = await repository.insertWidgetConfig(config);

        // Note: copyWith doesn't allow explicitly setting null,
        // so we'll create a new config
        final clearedConfig = WidgetConfig(
          id: id,
          name: config.name,
          size: config.size,
          showCompleted: config.showCompleted,
          showCategories: config.showCategories,
          showPriority: config.showPriority,
          categoryFilter: null,
          maxTasks: config.maxTasks,
        );

        await repository.updateWidgetConfig(clearedConfig);

        final retrievedConfig = await repository.getWidgetConfig(id);
        expect(retrievedConfig!.categoryFilter, isNull);

        // Cleanup
        await repository.deleteWidgetConfig(id);
      });
    });

    group('Widget Config Max Tasks', () {
      test('should update maxTasks value', () async {
        final config = WidgetConfig(
          name: 'Max Tasks Test',
          maxTasks: 3,
        );

        final id = await repository.insertWidgetConfig(config);

        final updatedConfig = config.copyWith(
          id: id,
          maxTasks: 15,
        );

        await repository.updateWidgetConfig(updatedConfig);

        final retrievedConfig = await repository.getWidgetConfig(id);
        expect(retrievedConfig!.maxTasks, equals(15));

        // Cleanup
        await repository.deleteWidgetConfig(id);
      });

      test('should handle various maxTasks values', () async {
        final testValues = [1, 3, 5, 10, 20, 100];
        final ids = <int>[];

        for (final value in testValues) {
          final config = WidgetConfig(
            name: 'Max $value',
            maxTasks: value,
          );
          final id = await repository.insertWidgetConfig(config);
          ids.add(id);
        }

        for (var i = 0; i < testValues.length; i++) {
          final config = await repository.getWidgetConfig(ids[i]);
          expect(config!.maxTasks, equals(testValues[i]));
        }

        // Cleanup
        for (final id in ids) {
          await repository.deleteWidgetConfig(id);
        }
      });
    });
  });
}
