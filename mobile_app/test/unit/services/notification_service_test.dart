import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/core/notifications/models/notification_settings.dart';

void main() {
  group('NotificationSettings Tests', () {
    group('NotificationSetting Model', () {
      test('should create a notification setting with exact time', () {
        final now = DateTime.now();
        final setting = NotificationSetting(
          taskId: 1,
          timeOption: NotificationTimeOption.exactTime,
          customTime: now,
        );

        expect(setting.timeOption, equals(NotificationTimeOption.exactTime));
        expect(setting.customTime, equals(now));
        expect(setting.taskId, equals(1));
      });

      test('should create a notification setting with predefined option', () {
        final setting = NotificationSetting(
          taskId: 2,
          timeOption: NotificationTimeOption.fifteenMinutesBefore,
        );

        expect(setting.timeOption, equals(NotificationTimeOption.fifteenMinutesBefore));
        expect(setting.customTime, isNull);
        expect(setting.taskId, equals(2));
      });

      test('should convert notification setting to map', () {
        final customTime = DateTime(2024, 12, 25, 10, 30);
        final setting = NotificationSetting(
          id: 1,
          taskId: 5,
          timeOption: NotificationTimeOption.custom,
          customTime: customTime,
        );

        final map = setting.toMap();

        expect(map['id'], equals(1));
        expect(map['taskId'], equals(5));
        expect(map['timeOption'], equals(NotificationTimeOption.custom.index));
        expect(map['customTime'], equals(customTime.millisecondsSinceEpoch));
      });

      test('should create notification setting from map', () {
        final customTime = DateTime(2024, 12, 25, 10, 30);
        final map = {
          'id': 2,
          'taskId': 10,
          'timeOption': NotificationTimeOption.oneDayBefore.index,
          'customTime': customTime.millisecondsSinceEpoch,
        };

        final setting = NotificationSetting.fromMap(map);

        expect(setting.id, equals(2));
        expect(setting.taskId, equals(10));
        expect(setting.timeOption, equals(NotificationTimeOption.oneDayBefore));
        expect(setting.customTime?.millisecondsSinceEpoch, equals(customTime.millisecondsSinceEpoch));
      });

      test('should handle null custom time in map conversion', () {
        final setting = NotificationSetting(
          taskId: 3,
          timeOption: NotificationTimeOption.thirtyMinutesBefore,
        );

        final map = setting.toMap();
        expect(map['customTime'], isNull);

        final fromMap = NotificationSetting.fromMap({
          'taskId': 3,
          'timeOption': NotificationTimeOption.thirtyMinutesBefore.index,
        });
        expect(fromMap.customTime, isNull);
      });

      test('should copy notification setting with new values', () {
        final original = NotificationSetting(
          id: 1,
          taskId: 5,
          timeOption: NotificationTimeOption.exactTime,
        );

        final copied = original.copyWith(
          timeOption: NotificationTimeOption.fifteenMinutesBefore,
          taskId: 10,
        );

        expect(copied.id, equals(1));
        expect(copied.taskId, equals(10));
        expect(copied.timeOption, equals(NotificationTimeOption.fifteenMinutesBefore));
      });
    });

    group('NotificationTimeOption Labels', () {
      test('should have correct label for exactTime', () {
        expect(NotificationTimeOption.exactTime.label, equals('At exact task time'));
      });

      test('should have correct label for fifteenMinutesBefore', () {
        expect(NotificationTimeOption.fifteenMinutesBefore.label, equals('15 minutes before'));
      });

      test('should have correct label for thirtyMinutesBefore', () {
        expect(NotificationTimeOption.thirtyMinutesBefore.label, equals('30 minutes before'));
      });

      test('should have correct label for oneHourBefore', () {
        expect(NotificationTimeOption.oneHourBefore.label, equals('1 hour before'));
      });

      test('should have correct label for oneDayBefore', () {
        expect(NotificationTimeOption.oneDayBefore.label, equals('1 day before'));
      });

      test('should have correct label for previousSunday', () {
        expect(NotificationTimeOption.previousSunday.label, equals('Previous Sunday'));
      });

      test('should have correct label for custom', () {
        expect(NotificationTimeOption.custom.label, equals('Custom time'));
      });
    });

    group('NotificationTimeOption Calculations', () {
      test('should calculate correct notification time for exactTime', () {
        final taskTime = DateTime(2024, 12, 25, 10, 0);
        final notificationTime = NotificationTimeOption.exactTime.calculateNotificationTime(taskTime, null);

        expect(notificationTime, equals(taskTime));
      });

      test('should calculate correct notification time for fifteenMinutesBefore', () {
        final taskTime = DateTime(2024, 12, 25, 10, 0);
        final notificationTime = NotificationTimeOption.fifteenMinutesBefore.calculateNotificationTime(taskTime, null);
        final expected = taskTime.subtract(const Duration(minutes: 15));

        expect(notificationTime, equals(expected));
      });

      test('should calculate correct notification time for thirtyMinutesBefore', () {
        final taskTime = DateTime(2024, 12, 25, 10, 0);
        final notificationTime = NotificationTimeOption.thirtyMinutesBefore.calculateNotificationTime(taskTime, null);
        final expected = taskTime.subtract(const Duration(minutes: 30));

        expect(notificationTime, equals(expected));
      });

      test('should calculate correct notification time for oneHourBefore', () {
        final taskTime = DateTime(2024, 12, 25, 10, 0);
        final notificationTime = NotificationTimeOption.oneHourBefore.calculateNotificationTime(taskTime, null);
        final expected = taskTime.subtract(const Duration(hours: 1));

        expect(notificationTime, equals(expected));
      });

      test('should calculate correct notification time for oneDayBefore', () {
        final taskTime = DateTime(2024, 12, 25, 10, 0);
        final notificationTime = NotificationTimeOption.oneDayBefore.calculateNotificationTime(taskTime, null);
        final expected = taskTime.subtract(const Duration(days: 1));

        expect(notificationTime, equals(expected));
      });

      test('should calculate correct notification time for custom option', () {
        final taskTime = DateTime(2024, 12, 25, 10, 0);
        final customTime = DateTime(2024, 12, 24, 8, 0);
        final notificationTime = NotificationTimeOption.custom.calculateNotificationTime(taskTime, customTime);

        expect(notificationTime, equals(customTime));
      });

      test('should use task time when custom time is null', () {
        final taskTime = DateTime(2024, 12, 25, 10, 0);
        final notificationTime = NotificationTimeOption.custom.calculateNotificationTime(taskTime, null);

        expect(notificationTime, equals(taskTime));
      });

      test('should calculate previous Sunday correctly for Monday', () {
        // Monday, December 23, 2024
        final taskTime = DateTime(2024, 12, 23, 10, 0);
        final notificationTime = NotificationTimeOption.previousSunday.calculateNotificationTime(taskTime, null);

        // Should be Sunday, December 22, 2024
        expect(notificationTime.weekday, equals(DateTime.sunday));
        expect(notificationTime.day, equals(22));
        expect(notificationTime.hour, equals(10));
        expect(notificationTime.minute, equals(0));
      });

      test('should calculate previous Sunday correctly for Sunday', () {
        // Sunday, December 22, 2024
        final taskTime = DateTime(2024, 12, 22, 10, 0);
        final notificationTime = NotificationTimeOption.previousSunday.calculateNotificationTime(taskTime, null);

        // Should be previous Sunday, December 15, 2024
        expect(notificationTime.weekday, equals(DateTime.sunday));
        expect(notificationTime.day, equals(15));
      });

      test('should calculate previous Sunday correctly for Wednesday', () {
        // Wednesday, December 25, 2024
        final taskTime = DateTime(2024, 12, 25, 15, 30);
        final notificationTime = NotificationTimeOption.previousSunday.calculateNotificationTime(taskTime, null);

        // Should be Sunday, December 22, 2024
        expect(notificationTime.weekday, equals(DateTime.sunday));
        expect(notificationTime.day, equals(22));
        expect(notificationTime.hour, equals(15));
        expect(notificationTime.minute, equals(30));
      });
    });

    group('Notification Scheduling Edge Cases', () {
      test('should handle notification time in the past', () {
        final pastTaskTime = DateTime.now().subtract(const Duration(hours: 2));
        final notificationTime = NotificationTimeOption.fifteenMinutesBefore.calculateNotificationTime(pastTaskTime, null);

        expect(notificationTime, isNotNull);
        expect(notificationTime.isBefore(DateTime.now()), isTrue);
      });

      test('should handle notification time very far in future', () {
        final futureTaskTime = DateTime.now().add(const Duration(days: 365));
        final notificationTime = NotificationTimeOption.oneDayBefore.calculateNotificationTime(futureTaskTime, null);
        final expected = futureTaskTime.subtract(const Duration(days: 1));

        expect(notificationTime, equals(expected));
      });

      test('should handle midnight times correctly', () {
        final midnightTask = DateTime(2024, 12, 25, 0, 0);
        final notificationTime = NotificationTimeOption.oneHourBefore.calculateNotificationTime(midnightTask, null);

        // Should be 11 PM on previous day
        expect(notificationTime.day, equals(24));
        expect(notificationTime.hour, equals(23));
        expect(notificationTime.minute, equals(0));
      });

      test('should handle month boundary correctly', () {
        final firstOfMonth = DateTime(2024, 12, 1, 10, 0);
        final notificationTime = NotificationTimeOption.oneDayBefore.calculateNotificationTime(firstOfMonth, null);

        // Should be November 30
        expect(notificationTime.month, equals(11));
        expect(notificationTime.day, equals(30));
      });
    });

    group('Multiple Notification Settings', () {
      test('should support multiple notifications for single task', () {
        final settings = [
          NotificationSetting(
            taskId: 1,
            timeOption: NotificationTimeOption.oneDayBefore,
          ),
          NotificationSetting(
            taskId: 1,
            timeOption: NotificationTimeOption.oneHourBefore,
          ),
          NotificationSetting(
            taskId: 1,
            timeOption: NotificationTimeOption.fifteenMinutesBefore,
          ),
        ];

        expect(settings.length, equals(3));
        expect(settings.every((s) => s.taskId == 1), isTrue);
        expect(settings.map((s) => s.timeOption).toSet().length, equals(3));
      });

      test('should maintain separate settings for different tasks', () {
        final task1Settings = NotificationSetting(
          taskId: 1,
          timeOption: NotificationTimeOption.exactTime,
        );

        final task2Settings = NotificationSetting(
          taskId: 2,
          timeOption: NotificationTimeOption.fifteenMinutesBefore,
        );

        expect(task1Settings.taskId, isNot(equals(task2Settings.taskId)));
      });
    });

    group('All NotificationTimeOption Values', () {
      test('should have all expected enum values', () {
        final allOptions = NotificationTimeOption.values;

        expect(allOptions, contains(NotificationTimeOption.exactTime));
        expect(allOptions, contains(NotificationTimeOption.fifteenMinutesBefore));
        expect(allOptions, contains(NotificationTimeOption.thirtyMinutesBefore));
        expect(allOptions, contains(NotificationTimeOption.oneHourBefore));
        expect(allOptions, contains(NotificationTimeOption.oneDayBefore));
        expect(allOptions, contains(NotificationTimeOption.previousSunday));
        expect(allOptions, contains(NotificationTimeOption.custom));
        expect(allOptions.length, equals(7));
      });
    });
  });
}
