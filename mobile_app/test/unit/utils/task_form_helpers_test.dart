import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:todo_app/features/tasks/utils/task_form_helpers.dart';

void main() {
  group('TaskFormHelpers Tests', () {
    group('combineDateAndTime', () {
      test('should combine date and time correctly', () {
        final date = DateTime(2024, 12, 25);
        const time = TimeOfDay(hour: 14, minute: 30);

        final result = TaskFormHelpers.combineDateAndTime(date, time);

        expect(result, equals(DateTime(2024, 12, 25, 14, 30)));
      });

      test('should return null when date is null', () {
        const time = TimeOfDay(hour: 14, minute: 30);

        final result = TaskFormHelpers.combineDateAndTime(null, time);

        expect(result, isNull);
      });

      test('should use current time when time is null', () {
        final date = DateTime(2024, 12, 25);
        final now = TimeOfDay.now();

        final result = TaskFormHelpers.combineDateAndTime(date, null);

        expect(result?.year, equals(2024));
        expect(result?.month, equals(12));
        expect(result?.day, equals(25));
        expect(result?.hour, equals(now.hour));
        expect(result?.minute, equals(now.minute));
      });

      test('should handle midnight time', () {
        final date = DateTime(2024, 12, 25);
        const time = TimeOfDay(hour: 0, minute: 0);

        final result = TaskFormHelpers.combineDateAndTime(date, time);

        expect(result, equals(DateTime(2024, 12, 25, 0, 0)));
      });

      test('should handle end of day time', () {
        final date = DateTime(2024, 12, 25);
        const time = TimeOfDay(hour: 23, minute: 59);

        final result = TaskFormHelpers.combineDateAndTime(date, time);

        expect(result, equals(DateTime(2024, 12, 25, 23, 59)));
      });
    });

    group('validateTaskTitle', () {
      test('should return null for valid title', () {
        final result = TaskFormHelpers.validateTaskTitle('Valid Task Title');

        expect(result, isNull);
      });

      test('should return error for null title', () {
        final result = TaskFormHelpers.validateTaskTitle(null);

        expect(result, equals('Please enter a title'));
      });

      test('should return error for empty title', () {
        final result = TaskFormHelpers.validateTaskTitle('');

        expect(result, equals('Please enter a title'));
      });

      test('should return error for whitespace-only title', () {
        final result = TaskFormHelpers.validateTaskTitle('   ');

        expect(result, equals('Please enter a title'));
      });

      test('should return error for title too short', () {
        final result = TaskFormHelpers.validateTaskTitle('Hi');

        expect(result, equals('Title must be at least 3 characters'));
      });

      test('should accept title with exactly 3 characters', () {
        final result = TaskFormHelpers.validateTaskTitle('Buy');

        expect(result, isNull);
      });

      test('should trim whitespace when validating length', () {
        final result = TaskFormHelpers.validateTaskTitle('  Hi  ');

        expect(result, equals('Title must be at least 3 characters'));
      });

      test('should accept long titles', () {
        final longTitle = 'This is a very long task title that should be accepted';
        final result = TaskFormHelpers.validateTaskTitle(longTitle);

        expect(result, isNull);
      });
    });

    group('isToday', () {
      test('should return true for today\'s date', () {
        final today = DateTime.now();
        final result = TaskFormHelpers.isToday(today);

        expect(result, isTrue);
      });

      test('should return true for today with different time', () {
        final now = DateTime.now();
        final todayDifferentTime = DateTime(now.year, now.month, now.day, 23, 59, 59);
        final result = TaskFormHelpers.isToday(todayDifferentTime);

        expect(result, isTrue);
      });

      test('should return false for yesterday', () {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        final result = TaskFormHelpers.isToday(yesterday);

        expect(result, isFalse);
      });

      test('should return false for tomorrow', () {
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        final result = TaskFormHelpers.isToday(tomorrow);

        expect(result, isFalse);
      });
    });

    group('isInPast', () {
      test('should return true for past date', () {
        final pastDate = DateTime.now().subtract(const Duration(days: 1));
        final result = TaskFormHelpers.isInPast(pastDate);

        expect(result, isTrue);
      });

      test('should return false for future date', () {
        final futureDate = DateTime.now().add(const Duration(days: 1));
        final result = TaskFormHelpers.isInPast(futureDate);

        expect(result, isFalse);
      });

      test('should return false for today', () {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final result = TaskFormHelpers.isInPast(today);

        expect(result, isFalse);
      });

      test('should consider only date, not time', () {
        final now = DateTime.now();
        final todayMorning = DateTime(now.year, now.month, now.day, 1, 0);
        final result = TaskFormHelpers.isInPast(todayMorning);

        expect(result, isFalse);
      });
    });

    group('formatTimeOfDay', () {
      testWidgets('should format AM time correctly', (WidgetTester tester) async {
        await tester.pumpWidget(MaterialApp(
          home: Builder(
            builder: (context) {
              const time = TimeOfDay(hour: 9, minute: 30);
              final formatted = TaskFormHelpers.formatTimeOfDay(time, context);
              expect(formatted, equals('9:30 AM'));
              return Container();
            },
          ),
        ));
      });

      testWidgets('should format PM time correctly', (WidgetTester tester) async {
        await tester.pumpWidget(MaterialApp(
          home: Builder(
            builder: (context) {
              const time = TimeOfDay(hour: 14, minute: 45);
              final formatted = TaskFormHelpers.formatTimeOfDay(time, context);
              expect(formatted, equals('2:45 PM'));
              return Container();
            },
          ),
        ));
      });

      testWidgets('should format midnight correctly', (WidgetTester tester) async {
        await tester.pumpWidget(MaterialApp(
          home: Builder(
            builder: (context) {
              const time = TimeOfDay(hour: 0, minute: 0);
              final formatted = TaskFormHelpers.formatTimeOfDay(time, context);
              expect(formatted, equals('12:00 AM'));
              return Container();
            },
          ),
        ));
      });

      testWidgets('should format noon correctly', (WidgetTester tester) async {
        await tester.pumpWidget(MaterialApp(
          home: Builder(
            builder: (context) {
              const time = TimeOfDay(hour: 12, minute: 0);
              final formatted = TaskFormHelpers.formatTimeOfDay(time, context);
              expect(formatted, equals('12:00 PM'));
              return Container();
            },
          ),
        ));
      });

      testWidgets('should pad minutes with zero', (WidgetTester tester) async {
        await tester.pumpWidget(MaterialApp(
          home: Builder(
            builder: (context) {
              const time = TimeOfDay(hour: 15, minute: 5);
              final formatted = TaskFormHelpers.formatTimeOfDay(time, context);
              expect(formatted, equals('3:05 PM'));
              return Container();
            },
          ),
        ));
      });
    });

    group('getNotificationTimeDescription', () {
      test('should return "At task time" for same time', () {
        final taskDate = DateTime(2024, 12, 25);
        const taskTime = TimeOfDay(hour: 14, minute: 30);
        const notificationTime = TimeOfDay(hour: 14, minute: 30);

        final description = TaskFormHelpers.getNotificationTimeDescription(
          taskDate,
          taskTime,
          notificationTime,
        );

        expect(description, equals('At task time'));
      });

      test('should return "15 minutes before" for 15-minute difference', () {
        final taskDate = DateTime(2024, 12, 25);
        const taskTime = TimeOfDay(hour: 14, minute: 30);
        const notificationTime = TimeOfDay(hour: 14, minute: 15);

        final description = TaskFormHelpers.getNotificationTimeDescription(
          taskDate,
          taskTime,
          notificationTime,
        );

        expect(description, equals('15 minutes before'));
      });

      test('should return "30 minutes before" for 30-minute difference', () {
        final taskDate = DateTime(2024, 12, 25);
        const taskTime = TimeOfDay(hour: 14, minute: 30);
        const notificationTime = TimeOfDay(hour: 14, minute: 0);

        final description = TaskFormHelpers.getNotificationTimeDescription(
          taskDate,
          taskTime,
          notificationTime,
        );

        expect(description, equals('30 minutes before'));
      });

      test('should return "1 hour before" for 60-minute difference', () {
        final taskDate = DateTime(2024, 12, 25);
        const taskTime = TimeOfDay(hour: 14, minute: 30);
        const notificationTime = TimeOfDay(hour: 13, minute: 30);

        final description = TaskFormHelpers.getNotificationTimeDescription(
          taskDate,
          taskTime,
          notificationTime,
        );

        expect(description, equals('1 hour before'));
      });

      test('should return custom description for other differences', () {
        final taskDate = DateTime(2024, 12, 25);
        const taskTime = TimeOfDay(hour: 14, minute: 30);
        const notificationTime = TimeOfDay(hour: 13, minute: 0);

        final description = TaskFormHelpers.getNotificationTimeDescription(
          taskDate,
          taskTime,
          notificationTime,
        );

        expect(description, equals('90 minutes before'));
      });

      test('should handle cross-day notifications', () {
        final taskDate = DateTime(2024, 12, 25);
        const taskTime = TimeOfDay(hour: 2, minute: 0); // 2:00 AM
        const notificationTime = TimeOfDay(hour: 0, minute: 0); // 12:00 AM (same day)

        final description = TaskFormHelpers.getNotificationTimeDescription(
          taskDate,
          taskTime,
          notificationTime,
        );

        // This would be 2 hours before
        expect(description, equals('120 minutes before'));
      });
    });
  });
}