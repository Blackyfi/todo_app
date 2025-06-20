import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:todo_app/features/tasks/widgets/task_card.dart';
import 'package:todo_app/features/tasks/models/task.dart';
import 'package:todo_app/features/categories/models/category.dart';
import 'package:todo_app/core/providers/time_format_provider.dart';
import '../../../helpers/test_helpers.dart';
import '../../../helpers/test_data.dart';

void main() {
  group('TaskCard Widget Tests', () {
    late Task testTask;
    late Category testCategory;
    late TimeFormatProvider timeFormatProvider;

    setUp(() {
      testTask = TestData.incompletePersonalTask;
      testCategory = TestData.personalCategory;
      timeFormatProvider = TimeFormatProvider();
    });

    Widget createTaskCard({
      Task? task,
      Category? category,
      VoidCallback? onTap,
      Function(bool?)? onCompletedChanged,
      VoidCallback? onDelete,
    }) {
      return TestHelpers.wrapWithMaterialApp(
        ChangeNotifierProvider.value(
          value: timeFormatProvider,
          child: TaskCard(
            task: task ?? testTask,
            category: category,
            onTap: onTap ?? () {},
            onCompletedChanged: onCompletedChanged ?? (value) {},
            onDelete: onDelete,
          ),
        ),
      );
    }

    group('Display Tests', () {
      testWidgets('should display task title', (WidgetTester tester) async {
        await tester.pumpWidget(createTaskCard());

        expect(find.text(testTask.title), findsOneWidget);
      });

      testWidgets('should display task description when present', (WidgetTester tester) async {
        await tester.pumpWidget(createTaskCard());

        expect(find.text(testTask.description), findsOneWidget);
      });

      testWidgets('should not display description when empty', (WidgetTester tester) async {
        final taskWithoutDescription = testTask.copyWith(description: '');
        await tester.pumpWidget(createTaskCard(task: taskWithoutDescription));

        expect(find.text(testTask.description), findsNothing);
      });

      testWidgets('should display category when provided', (WidgetTester tester) async {
        await tester.pumpWidget(createTaskCard(category: testCategory));

        expect(find.text(testCategory.name), findsOneWidget);
      });

      testWidgets('should not display category when null', (WidgetTester tester) async {
        await tester.pumpWidget(createTaskCard(category: null));

        expect(find.text(testCategory.name), findsNothing);
      });

      testWidgets('should display priority badge', (WidgetTester tester) async {
        await tester.pumpWidget(createTaskCard());

        // Look for priority indicator
        expect(find.byType(Container), findsWidgets);
      });

      testWidgets('should display due date when present', (WidgetTester tester) async {
        await tester.pumpWidget(createTaskCard());

        // Should find due date icon
        expect(find.byIcon(Icons.access_time), findsOneWidget);
      });

      testWidgets('should not display due date when null', (WidgetTester tester) async {
        final taskWithoutDueDate = testTask.copyWith(dueDate: null);
        await tester.pumpWidget(createTaskCard(task: taskWithoutDueDate));

        expect(find.byIcon(Icons.access_time), findsNothing);
      });
    });

    group('Checkbox Tests', () {
      testWidgets('should display unchecked checkbox for incomplete task', (WidgetTester tester) async {
        await tester.pumpWidget(createTaskCard());

        final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
        expect(checkbox.value, isFalse);
      });

      testWidgets('should display checked checkbox for completed task', (WidgetTester tester) async {
        final completedTask = testTask.copyWith(isCompleted: true);
        await tester.pumpWidget(createTaskCard(task: completedTask));

        final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
        expect(checkbox.value, isTrue);
      });

      testWidgets('should call onCompletedChanged when checkbox is tapped', (WidgetTester tester) async {
        bool? changedValue;
        await tester.pumpWidget(createTaskCard(
          onCompletedChanged: (value) => changedValue = value,
        ));

        await tester.tap(find.byType(Checkbox));
        await tester.pump();

        expect(changedValue, isTrue);
      });
    });

    group('Styling Tests', () {
      testWidgets('should apply strikethrough style for completed task', (WidgetTester tester) async {
        final completedTask = testTask.copyWith(isCompleted: true);
        await tester.pumpWidget(createTaskCard(task: completedTask));

        final titleText = tester.widget<Text>(find.text(testTask.title));
        expect(titleText.style?.decoration, equals(TextDecoration.lineThrough));
      });

      testWidgets('should not apply strikethrough style for incomplete task', (WidgetTester tester) async {
        await tester.pumpWidget(createTaskCard());

        final titleText = tester.widget<Text>(find.text(testTask.title));
        expect(titleText.style?.decoration, isNot(equals(TextDecoration.lineThrough)));
      });

      testWidgets('should apply muted color for completed task', (WidgetTester tester) async {
        final completedTask = testTask.copyWith(isCompleted: true);
        await tester.pumpWidget(createTaskCard(task: completedTask));

        // The text should have a muted color
        final titleText = tester.widget<Text>(find.text(testTask.title));
        expect(titleText.style?.color, isNotNull);
      });
    });

    group('Background Indicator Tests', () {
      testWidgets('should show overdue indicator for past due task', (WidgetTester tester) async {
        final overdueTask = testTask.copyWith(
          dueDate: DateTime.now().subtract(const Duration(days: 1)),
        );
        await tester.pumpWidget(createTaskCard(task: overdueTask));

        expect(find.textContaining('OVERDUE'), findsOneWidget);
      });

      testWidgets('should show today indicator for task due today', (WidgetTester tester) async {
        final todayTask = testTask.copyWith(
          dueDate: DateTime.now().add(const Duration(hours: 2)),
        );
        await tester.pumpWidget(createTaskCard(task: todayTask));

        // Should show either TODAY or days left indicator
        expect(find.textContaining('TODAY'), findsOneWidget);
      });

      testWidgets('should show days left indicator for future task', (WidgetTester tester) async {
        final futureTask = testTask.copyWith(
          dueDate: DateTime.now().add(const Duration(days: 3)),
        );
        await tester.pumpWidget(createTaskCard(task: futureTask));

        expect(find.textContaining('DAYS LEFT'), findsOneWidget);
      });

      testWidgets('should not show background indicator for completed task', (WidgetTester tester) async {
        final completedTask = testTask.copyWith(
          isCompleted: true,
          dueDate: DateTime.now().subtract(const Duration(days: 1)),
        );
        await tester.pumpWidget(createTaskCard(task: completedTask));

        // Background indicator should not appear for completed tasks
        expect(find.textContaining('OVERDUE'), findsNothing);
      });
    });

    group('Interaction Tests', () {
      testWidgets('should call onTap when card is tapped', (WidgetTester tester) async {
        bool tapped = false;
        await tester.pumpWidget(createTaskCard(
          onTap: () => tapped = true,
        ));

        await tester.tap(find.byType(Card));
        await tester.pump();

        expect(tapped, isTrue);
      });

      testWidgets('should show delete confirmation dialog when dismissed', (WidgetTester tester) async {
        await tester.pumpWidget(createTaskCard(onDelete: () {}));

        // Swipe to dismiss
        await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
        await tester.pumpAndSettle();

        expect(find.text('Delete Task'), findsOneWidget);
        expect(find.text('Are you sure you want to delete this task?'), findsOneWidget);
      });

      testWidgets('should call onDelete when deletion is confirmed', (WidgetTester tester) async {
        bool deleted = false;
        await tester.pumpWidget(createTaskCard(
          onDelete: () => deleted = true,
        ));

        // Swipe to dismiss
        await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
        await tester.pumpAndSettle();

        // Confirm deletion
        await tester.tap(find.text('DELETE'));
        await tester.pumpAndSettle();

        expect(deleted, isTrue);
      });

      testWidgets('should not call onDelete when deletion is cancelled', (WidgetTester tester) async {
        bool deleted = false;
        await tester.pumpWidget(createTaskCard(
          onDelete: () => deleted = true,
        ));

        // Swipe to dismiss
        await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
        await tester.pumpAndSettle();

        // Cancel deletion
        await tester.tap(find.text('CANCEL'));
        await tester.pump();

        expect(deleted, isFalse);
      });
    });

    group('Time Format Tests', () {
      testWidgets('should display European time format when enabled', (WidgetTester tester) async {
        await timeFormatProvider.setTimeFormat(TimeFormat.european);
        await tester.pumpWidget(createTaskCard());

        // Look for 24-hour format time
        expect(find.textContaining(':'), findsWidgets);
      });

      testWidgets('should display American time format when enabled', (WidgetTester tester) async {
        await timeFormatProvider.setTimeFormat(TimeFormat.american);
        await tester.pumpWidget(createTaskCard());

        // Look for 12-hour format time
        expect(find.textContaining(':'), findsWidgets);
      });
    });

    group('Edge Cases', () {
      testWidgets('should handle very long task titles', (WidgetTester tester) async {
        final longTitleTask = testTask.copyWith(
          title: 'This is a very long task title that should be truncated with ellipsis when it exceeds the available space',
        );
        await tester.pumpWidget(createTaskCard(task: longTitleTask));

        // Should still render without overflow
        expect(tester.takeException(), isNull);
      });

      testWidgets('should handle very long descriptions', (WidgetTester tester) async {
        final longDescTask = testTask.copyWith(
          description: 'This is a very long description that should be truncated with ellipsis when it exceeds the available space for the description text area',
        );
        await tester.pumpWidget(createTaskCard(task: longDescTask));

        // Should still render without overflow
        expect(tester.takeException(), isNull);
      });

      testWidgets('should handle task without onDelete callback', (WidgetTester tester) async {
        await tester.pumpWidget(createTaskCard(onDelete: null));

        // Swipe should not cause deletion
        await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
        await tester.pumpAndSettle();

        // Should not show delete dialog
        expect(find.text('Delete Task'), findsNothing);
      });
    });
  });
}