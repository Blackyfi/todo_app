import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:todo_app/core/database/repository/notification_repository.dart';
import 'package:todo_app/core/notifications/models/notification_settings.dart';

void main() {
  // Initialize FFI for testing
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('NotificationRepository Tests', () {
    late NotificationRepository repository;

    setUp(() {
      repository = NotificationRepository();
    });

    group('Notification Setting CRUD Operations', () {
      test('should insert and retrieve a notification setting', () async {
        final setting = NotificationSetting(
          taskId: 1,
          timeOption: NotificationTimeOption.fifteenMinutesBefore,
        );

        final id = await repository.insertNotificationSetting(setting);
        expect(id, isPositive);

        final settings = await repository.getNotificationSettingsForTask(1);
        expect(settings.length, greaterThan(0));

        final retrievedSetting = settings.firstWhere((s) => s.id == id);
        expect(retrievedSetting.taskId, equals(1));
        expect(retrievedSetting.timeOption, equals(NotificationTimeOption.fifteenMinutesBefore));
        expect(retrievedSetting.customTime, isNull);

        // Cleanup
        await repository.deleteNotificationSetting(id);
      });

      test('should insert notification setting with custom time', () async {
        final customTime = DateTime.now().add(const Duration(hours: 2));
        final setting = NotificationSetting(
          taskId: 2,
          timeOption: NotificationTimeOption.custom,
          customTime: customTime,
        );

        final id = await repository.insertNotificationSetting(setting);
        expect(id, isPositive);

        final settings = await repository.getNotificationSettingsForTask(2);
        final retrievedSetting = settings.firstWhere((s) => s.id == id);

        expect(retrievedSetting.timeOption, equals(NotificationTimeOption.custom));
        expect(retrievedSetting.customTime, isNotNull);
        expect(
          retrievedSetting.customTime!.difference(customTime).inSeconds.abs(),
          lessThan(1),
        );

        // Cleanup
        await repository.deleteNotificationSetting(id);
      });

      test('should update an existing notification setting', () async {
        final setting = NotificationSetting(
          taskId: 3,
          timeOption: NotificationTimeOption.exactTime,
        );

        final id = await repository.insertNotificationSetting(setting);

        final updatedSetting = setting.copyWith(
          id: id,
          timeOption: NotificationTimeOption.oneHourBefore,
        );

        await repository.updateNotificationSetting(updatedSetting);

        final settings = await repository.getNotificationSettingsForTask(3);
        final retrievedSetting = settings.firstWhere((s) => s.id == id);

        expect(retrievedSetting.timeOption, equals(NotificationTimeOption.oneHourBefore));

        // Cleanup
        await repository.deleteNotificationSetting(id);
      });

      test('should delete a notification setting', () async {
        final setting = NotificationSetting(
          taskId: 4,
          timeOption: NotificationTimeOption.oneDayBefore,
        );

        final id = await repository.insertNotificationSetting(setting);

        final deleteResult = await repository.deleteNotificationSetting(id);
        expect(deleteResult, equals(1));

        final settings = await repository.getNotificationSettingsForTask(4);
        final hasDeletedSetting = settings.any((s) => s.id == id);
        expect(hasDeletedSetting, isFalse);
      });
    });

    group('Get Notification Settings for Task', () {
      test('should retrieve multiple notification settings for a task', () async {
        final setting1 = NotificationSetting(
          taskId: 5,
          timeOption: NotificationTimeOption.fifteenMinutesBefore,
        );
        final setting2 = NotificationSetting(
          taskId: 5,
          timeOption: NotificationTimeOption.oneDayBefore,
        );
        final setting3 = NotificationSetting(
          taskId: 5,
          timeOption: NotificationTimeOption.exactTime,
        );

        final id1 = await repository.insertNotificationSetting(setting1);
        final id2 = await repository.insertNotificationSetting(setting2);
        final id3 = await repository.insertNotificationSetting(setting3);

        final settings = await repository.getNotificationSettingsForTask(5);

        final ourSettings = settings.where((s) =>
          s.id == id1 || s.id == id2 || s.id == id3
        ).toList();

        expect(ourSettings.length, equals(3));
        expect(ourSettings.any((s) => s.timeOption == NotificationTimeOption.fifteenMinutesBefore), isTrue);
        expect(ourSettings.any((s) => s.timeOption == NotificationTimeOption.oneDayBefore), isTrue);
        expect(ourSettings.any((s) => s.timeOption == NotificationTimeOption.exactTime), isTrue);

        // Cleanup
        await repository.deleteNotificationSetting(id1);
        await repository.deleteNotificationSetting(id2);
        await repository.deleteNotificationSetting(id3);
      });

      test('should return empty list for task with no notification settings', () async {
        final settings = await repository.getNotificationSettingsForTask(99999);
        expect(settings, isEmpty);
      });
    });

    group('Get All Notification Settings', () {
      test('should retrieve all notification settings across all tasks', () async {
        final setting1 = NotificationSetting(
          taskId: 6,
          timeOption: NotificationTimeOption.exactTime,
        );
        final setting2 = NotificationSetting(
          taskId: 7,
          timeOption: NotificationTimeOption.thirtyMinutesBefore,
        );

        final id1 = await repository.insertNotificationSetting(setting1);
        final id2 = await repository.insertNotificationSetting(setting2);

        final allSettings = await repository.getAllNotificationSettings();

        expect(allSettings.length, greaterThanOrEqualTo(2));
        expect(allSettings.any((s) => s.id == id1), isTrue);
        expect(allSettings.any((s) => s.id == id2), isTrue);

        // Cleanup
        await repository.deleteNotificationSetting(id1);
        await repository.deleteNotificationSetting(id2);
      });
    });

    group('Delete Notification Settings for Task', () {
      test('should delete all notification settings for a specific task', () async {
        final setting1 = NotificationSetting(
          taskId: 8,
          timeOption: NotificationTimeOption.exactTime,
        );
        final setting2 = NotificationSetting(
          taskId: 8,
          timeOption: NotificationTimeOption.fifteenMinutesBefore,
        );
        final setting3 = NotificationSetting(
          taskId: 9,
          timeOption: NotificationTimeOption.oneDayBefore,
        );

        await repository.insertNotificationSetting(setting1);
        await repository.insertNotificationSetting(setting2);
        final id3 = await repository.insertNotificationSetting(setting3);

        final deleteCount = await repository.deleteNotificationSettingsForTask(8);
        expect(deleteCount, greaterThanOrEqualTo(2));

        final task8Settings = await repository.getNotificationSettingsForTask(8);
        expect(task8Settings, isEmpty);

        // Task 9's setting should still exist
        final task9Settings = await repository.getNotificationSettingsForTask(9);
        expect(task9Settings.any((s) => s.id == id3), isTrue);

        // Cleanup
        await repository.deleteNotificationSetting(id3);
      });

      test('should return 0 when deleting from task with no settings', () async {
        final deleteCount = await repository.deleteNotificationSettingsForTask(99999);
        expect(deleteCount, equals(0));
      });
    });

    group('All Notification Time Options', () {
      test('should correctly store all notification time options', () async {
        final timeOptions = [
          NotificationTimeOption.exactTime,
          NotificationTimeOption.fifteenMinutesBefore,
          NotificationTimeOption.thirtyMinutesBefore,
          NotificationTimeOption.oneHourBefore,
          NotificationTimeOption.oneDayBefore,
          NotificationTimeOption.previousSunday,
          NotificationTimeOption.custom,
        ];

        final ids = <int>[];

        for (var i = 0; i < timeOptions.length; i++) {
          final setting = NotificationSetting(
            taskId: 10,
            timeOption: timeOptions[i],
            customTime: timeOptions[i] == NotificationTimeOption.custom
                ? DateTime.now()
                : null,
          );
          final id = await repository.insertNotificationSetting(setting);
          ids.add(id);
        }

        final settings = await repository.getNotificationSettingsForTask(10);
        final ourSettings = settings.where((s) => ids.contains(s.id)).toList();

        expect(ourSettings.length, equals(timeOptions.length));

        for (final option in timeOptions) {
          expect(ourSettings.any((s) => s.timeOption == option), isTrue);
        }

        // Cleanup
        for (final id in ids) {
          await repository.deleteNotificationSetting(id);
        }
      });
    });
  });
}
