import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/core/notifications/models/notification_settings.dart';

void main() {
  group('NotificationSetting Model Tests', () {
    late NotificationSetting testSetting;
    late DateTime customTime;

    setUp(() {
      customTime = DateTime(2024, 12, 25, 10, 30);
      testSetting = NotificationSetting(
        id: 1,
        taskId: 123,
        timeOption: NotificationTimeOption.fifteenMinutesBefore,
        customTime: customTime,
      );
    });

    test('should create a notification setting with all properties', () {
      expect(testSetting.id, equals(1));
      expect(testSetting.taskId, equals(123));
      expect(testSetting.timeOption, equals(NotificationTimeOption.fifteenMinutesBefore));
      expect(testSetting.customTime, equals(customTime));
    });

    test('should create a notification setting without id and custom time', () {
      final simpleSetting = NotificationSetting(
        taskId: 456,
        timeOption: NotificationTimeOption.exactTime,
      );

      expect(simpleSetting.id, isNull);
      expect(simpleSetting.taskId, equals(456));
      expect(simpleSetting.timeOption, equals(NotificationTimeOption.exactTime));
      expect(simpleSetting.customTime, isNull);
    });

    test('should copy notification setting with new values', () {
      final copiedSetting = testSetting.copyWith(
        taskId: 789,
        timeOption: NotificationTimeOption.oneHourBefore,
      );

      expect(copiedSetting.id, equals(testSetting.id));
      expect(copiedSetting.taskId, equals(789));
      expect(copiedSetting.timeOption, equals(NotificationTimeOption.oneHourBefore));
      expect(copiedSetting.customTime, equals(testSetting.customTime));
    });

    test('should convert to map correctly', () {
      final map = testSetting.toMap();

      expect(map['id'], equals(1));
      expect(map['taskId'], equals(123));
      expect(map['timeOption'], equals(NotificationTimeOption.fifteenMinutesBefore.index));
      expect(map['customTime'], equals(customTime.millisecondsSinceEpoch));
    });

    test('should create from map correctly', () {
      final map = {
        'id': 2,
        'taskId': 789,
        'timeOption': NotificationTimeOption.custom.index,
        'customTime': customTime.millisecondsSinceEpoch,
      };

      final settingFromMap = NotificationSetting.fromMap(map);

      expect(settingFromMap.id, equals(2));
      expect(settingFromMap.taskId, equals(789));
      expect(settingFromMap.timeOption, equals(NotificationTimeOption.custom));
      expect(settingFromMap.customTime, equals(customTime));
    });

    test('should handle null values in fromMap', () {
      final map = {
        'taskId': 999,
        'timeOption': NotificationTimeOption.exactTime.index,
      };

      final settingFromMap = NotificationSetting.fromMap(map);

      expect(settingFromMap.id, isNull);
      expect(settingFromMap.taskId, equals(999));
      expect(settingFromMap.timeOption, equals(NotificationTimeOption.exactTime));
      expect(settingFromMap.customTime, isNull);
    });
  });

  group('NotificationTimeOption Extension Tests', () {
    test('should have correct labels', () {
      expect(NotificationTimeOption.exactTime.label, equals('At exact task time'));
      expect(NotificationTimeOption.fifteenMinutesBefore.label, equals('15 minutes before'));
      expect(NotificationTimeOption.thirtyMinutesBefore.label, equals('30 minutes before'));
      expect(NotificationTimeOption.oneHourBefore.label, equals('1 hour before'));
      expect(NotificationTimeOption.oneDayBefore.label, equals('1 day before'));
      expect(NotificationTimeOption.previousSunday.label, equals('Previous Sunday'));
      expect(NotificationTimeOption.custom.label, equals('Custom time'));
    });

    test('should calculate notification time correctly', () {
      final taskTime = DateTime(2024, 12, 25, 14, 30); // Tuesday
      final customTime = DateTime(2024, 12, 25, 10, 0);

      expect(
        NotificationTimeOption.exactTime.calculateNotificationTime(taskTime, null),
        equals(taskTime),
      );

      expect(
        NotificationTimeOption.fifteenMinutesBefore.calculateNotificationTime(taskTime, null),
        equals(taskTime.subtract(const Duration(minutes: 15))),
      );

      expect(
        NotificationTimeOption.thirtyMinutesBefore.calculateNotificationTime(taskTime, null),
        equals(taskTime.subtract(const Duration(minutes: 30))),
      );

      expect(
        NotificationTimeOption.oneHourBefore.calculateNotificationTime(taskTime, null),
        equals(taskTime.subtract(const Duration(hours: 1))),
      );

      expect(
        NotificationTimeOption.oneDayBefore.calculateNotificationTime(taskTime, null),
        equals(taskTime.subtract(const Duration(days: 1))),
      );

      expect(
        NotificationTimeOption.custom.calculateNotificationTime(taskTime, customTime),
        equals(customTime),
      );
    });

    test('should calculate previous Sunday correctly', () {
      // Test for Tuesday (weekday 2)
      final tuesdayTask = DateTime(2024, 12, 24, 14, 30); // Tuesday
      final expectedSunday = DateTime(2024, 12, 22, 14, 30); // Previous Sunday

      final result = NotificationTimeOption.previousSunday.calculateNotificationTime(tuesdayTask, null);
      expect(result, equals(expectedSunday));

      // Test for Sunday (weekday 7)
      final sundayTask = DateTime(2024, 12, 22, 14, 30); // Sunday
      final expectedPreviousSunday = DateTime(2024, 12, 15, 14, 30); // Previous Sunday

      final sundayResult = NotificationTimeOption.previousSunday.calculateNotificationTime(sundayTask, null);
      expect(sundayResult, equals(expectedPreviousSunday));
    });

    test('should fallback to task time when custom time is null', () {
      final taskTime = DateTime(2024, 12, 25, 14, 30);

      final result = NotificationTimeOption.custom.calculateNotificationTime(taskTime, null);
      expect(result, equals(taskTime));
    });
  });
}