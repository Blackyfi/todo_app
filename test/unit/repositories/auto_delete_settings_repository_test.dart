import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:todo_app/core/settings/repository/auto_delete_settings_repository.dart';
import 'package:todo_app/core/settings/models/auto_delete_settings.dart';

void main() {
  // Initialize FFI for testing
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('AutoDeleteSettingsRepository Tests', () {
    late AutoDeleteSettingsRepository repository;

    setUp(() {
      repository = AutoDeleteSettingsRepository();
    });

    group('Get Settings', () {
      test('should return default settings when no settings exist', () async {
        // The getSettings method will create defaults if none exist
        final settings = await repository.getSettings();

        expect(settings, isNotNull);
        expect(settings.id, isNotNull);
        expect(settings.deleteImmediately, isFalse);
        expect(settings.deleteAfterDays, equals(1));

        // Cleanup - Note: We can't really clean up the default settings
        // as they are automatically created, but that's fine for testing
      });

      test('should retrieve existing settings', () async {
        final customSettings = AutoDeleteSettings(
          deleteImmediately: true,
          deleteAfterDays: 7,
        );

        // Insert custom settings
        final id = await repository.insertSettings(customSettings);

        // Get settings should return the custom settings
        final retrievedSettings = await repository.getSettings();

        expect(retrievedSettings.id, isNotNull);
        expect(retrievedSettings.deleteImmediately, isTrue);
        expect(retrievedSettings.deleteAfterDays, equals(7));
      });
    });

    group('Insert Settings', () {
      test('should insert settings with default values', () async {
        final settings = AutoDeleteSettings();

        await repository.insertSettings(settings);

        // Verify by retrieving
        final retrieved = await repository.getSettings();
        expect(retrieved.deleteImmediately, isFalse);
        expect(retrieved.deleteAfterDays, equals(1));
      });

      test('should insert settings with custom values', () async {
        final settings = AutoDeleteSettings(
          deleteImmediately: true,
          deleteAfterDays: 30,
        );

        await repository.insertSettings(settings);

        // Verify by retrieving
        final retrieved = await repository.getSettings();
        expect(retrieved.deleteImmediately, isTrue);
        expect(retrieved.deleteAfterDays, equals(30));
      });
    });

    group('Update Settings', () {
      test('should update deleteImmediately setting', () async {
        // Get or create initial settings
        final initialSettings = await repository.getSettings();

        final updatedSettings = initialSettings.copyWith(
          deleteImmediately: true,
        );

        final result = await repository.updateSettings(updatedSettings);
        expect(result, greaterThan(0));

        final retrievedSettings = await repository.getSettings();
        expect(retrievedSettings.deleteImmediately, isTrue);
      });

      test('should update deleteAfterDays setting', () async {
        final initialSettings = await repository.getSettings();

        final updatedSettings = initialSettings.copyWith(
          deleteAfterDays: 14,
        );

        final result = await repository.updateSettings(updatedSettings);
        expect(result, greaterThan(0));

        final retrievedSettings = await repository.getSettings();
        expect(retrievedSettings.deleteAfterDays, equals(14));
      });

      test('should update both settings simultaneously', () async {
        final initialSettings = await repository.getSettings();

        final updatedSettings = initialSettings.copyWith(
          deleteImmediately: false,
          deleteAfterDays: 3,
        );

        await repository.updateSettings(updatedSettings);

        final retrievedSettings = await repository.getSettings();
        expect(retrievedSettings.deleteImmediately, isFalse);
        expect(retrievedSettings.deleteAfterDays, equals(3));
      });

      test('should toggle deleteImmediately back and forth', () async {
        final initialSettings = await repository.getSettings();

        // Toggle to true
        await repository.updateSettings(
          initialSettings.copyWith(deleteImmediately: true),
        );

        var settings = await repository.getSettings();
        expect(settings.deleteImmediately, isTrue);

        // Toggle to false
        await repository.updateSettings(
          settings.copyWith(deleteImmediately: false),
        );

        settings = await repository.getSettings();
        expect(settings.deleteImmediately, isFalse);
      });
    });

    group('Delete After Days Values', () {
      test('should handle various deleteAfterDays values', () async {
        final testValues = [1, 3, 7, 14, 30, 60, 90];

        for (final value in testValues) {
          final settings = await repository.getSettings();
          final updated = settings.copyWith(deleteAfterDays: value);

          await repository.updateSettings(updated);

          final retrieved = await repository.getSettings();
          expect(
            retrieved.deleteAfterDays,
            equals(value),
            reason: 'deleteAfterDays should be $value',
          );
        }
      });

      test('should handle edge case values', () async {
        final edgeCases = [0, 1, 365, 1000];

        for (final value in edgeCases) {
          final settings = await repository.getSettings();
          final updated = settings.copyWith(deleteAfterDays: value);

          await repository.updateSettings(updated);

          final retrieved = await repository.getSettings();
          expect(retrieved.deleteAfterDays, equals(value));
        }
      });
    });

    group('Settings Persistence', () {
      test('should persist settings across multiple retrievals', () async {
        final settings = await repository.getSettings();

        final updated = settings.copyWith(
          deleteImmediately: true,
          deleteAfterDays: 21,
        );

        await repository.updateSettings(updated);

        // Retrieve multiple times to verify persistence
        for (var i = 0; i < 3; i++) {
          final retrieved = await repository.getSettings();
          expect(retrieved.deleteImmediately, isTrue);
          expect(retrieved.deleteAfterDays, equals(21));
        }
      });
    });

    group('Settings Model', () {
      test('should correctly convert to and from map', () async {
        final original = AutoDeleteSettings(
          id: 1,
          deleteImmediately: true,
          deleteAfterDays: 5,
        );

        final map = original.toMap();

        expect(map['id'], equals(1));
        expect(map['deleteImmediately'], equals(1)); // Stored as int
        expect(map['deleteAfterDays'], equals(5));

        final fromMap = AutoDeleteSettings.fromMap(map);

        expect(fromMap.id, equals(original.id));
        expect(fromMap.deleteImmediately, equals(original.deleteImmediately));
        expect(fromMap.deleteAfterDays, equals(original.deleteAfterDays));
      });

      test('should handle copyWith correctly', () async {
        final original = AutoDeleteSettings(
          id: 1,
          deleteImmediately: false,
          deleteAfterDays: 10,
        );

        final copied = original.copyWith(
          deleteImmediately: true,
        );

        expect(copied.id, equals(1));
        expect(copied.deleteImmediately, isTrue);
        expect(copied.deleteAfterDays, equals(10)); // Unchanged

        final copied2 = original.copyWith(
          deleteAfterDays: 20,
        );

        expect(copied2.id, equals(1));
        expect(copied2.deleteImmediately, isFalse); // Unchanged
        expect(copied2.deleteAfterDays, equals(20));
      });
    });

    group('Concurrent Updates', () {
      test('should handle sequential updates correctly', () async {
        final settings = await repository.getSettings();

        // Perform multiple sequential updates
        for (var i = 1; i <= 5; i++) {
          final updated = settings.copyWith(
            id: settings.id,
            deleteAfterDays: i,
          );
          await repository.updateSettings(updated);
        }

        final finalSettings = await repository.getSettings();
        expect(finalSettings.deleteAfterDays, equals(5));
      });
    });
  });
}
