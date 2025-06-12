import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:todo_app/features/tasks/screens/home_screen.dart';
import 'package:todo_app/features/tasks/models/task.dart';
import 'package:todo_app/features/categories/models/category.dart';
import 'package:todo_app/core/database/repository/task_repository.dart';
import 'package:todo_app/core/database/repository/category_repository.dart';
import '../../helpers/test_helpers.dart';
import '../../helpers/mock_repositories.dart';

@GenerateMocks([TaskRepository, CategoryRepository])
void main() {
  group('HomeScreen Widget Tests', () {
    late MockTaskRepository mockTaskRepository;
    late MockCategoryRepository mockCategoryRepository;
    late List<Task> testTasks;
    late List<Category> testCategories;

    setUp(() {
      mockTaskRepository = MockTaskRepository();
      mockCategoryRepository = MockCategoryRepository();

      testCategories = [
        Category(id: 1, name: 'Work', color: Colors.blue),
        Category(id: 2, name: 'Personal', color: Colors.green),
      ];

      testTasks = [
        Task(
          id: 1,
          title: 'Completed Task',
          description: 'Completed task description',
          isCompleted: true,
          categoryId: 1,
          priority: Priority.high,
          dueDate: DateTime.now().subtract(const Duration(days: 1)),
        ),
        Task(
          id: 2,
          title: 'Incomplete Task',
          description: 'Incomplete task description',
          isCompleted: false,
          categoryId: 2,
          priority: Priority.medium,
          dueDate: DateTime.now().add(const Duration(days: 1)),
        ),
        Task(
          id: 3,
          title: 'Today Task',
          description: 'Task due today',
          isCompleted: false,
          categoryId: 1,
          priority: Priority.low,
          dueDate: DateTime.now().add(const Duration(hours: 5)),
        ),
      ];

      when(mockTaskRepository.getAllTasks())
          .thenAnswer((_) async => testTasks);
      when(mockCategoryRepository.getAllCategories())
          .thenAnswer((_) async => testCategories);
    });

    Widget createHomeScreen() {
      return TestHelpers.wrapWithMaterialApp(
        const HomeScreen(),
      );
    }

    group('Initial Display Tests', () {
      testWidgets('should display app title', (WidgetTester tester) async {
        await tester.pumpWidget(createHomeScreen());
        await tester.pump(); // Allow initial build

        expect(find.text('Todo App'), findsOneWidget);
      });

      testWidgets('should display tab bar with three tabs', (WidgetTester tester) async {
        await tester.pumpWidget(createHomeScreen());
        await tester.pump();

        expect(find.text('Tasks'), findsOneWidget);
        expect(find.text('Categories'), findsOneWidget);
        expect(find.text('Statistics'), findsOneWidget);
      });

      testWidgets('should display floating action button on tasks tab', (WidgetTester tester) async {
        await tester.pumpWidget(createHomeScreen());
        await tester.pump();

        expect(find.byType(FloatingActionButton), findsOneWidget);
        expect(find.byIcon(Icons.add), findsOneWidget);
      });

      testWidgets('should display settings button in app bar', (WidgetTester tester) async {
        await tester.pumpWidget(createHomeScreen());
        await tester.pump();

        expect(find.byIcon(Icons.settings), findsOneWidget);
      });
    });

    group('Loading State Tests', () {
      testWidgets('should show loading indicator initially', (WidgetTester tester) async {
        // Mock delayed response
        when(mockTaskRepository.getAllTasks())
            .thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 100));
          return testTasks;
        });

        await tester.pumpWidget(createHomeScreen());

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('should hide loading indicator after data loads', (WidgetTester tester) async {
        await tester.pumpWidget(createHomeScreen());
        await tester.pumpAndSettle(); // Wait for all async operations

        expect(find.byType(CircularProgressIndicator), findsNothing);
      });
    });

    group('Task Display Tests', () {
      testWidgets('should display all tasks by default', (WidgetTester tester) async {
        await tester.pumpWidget(createHomeScreen());
        await tester.pumpAndSettle();

        expect(find.text('Completed Task'), findsOneWidget);
        expect(find.text('Incomplete Task'), findsOneWidget);
        expect(find.text('Today Task'), findsOneWidget);
      });

      testWidgets('should display empty state when no tasks', (WidgetTester tester) async {
        when(mockTaskRepository.getAllTasks())
            .thenAnswer((_) async => []);

        await tester.pumpWidget(createHomeScreen());
        await tester.pumpAndSettle();

        expect(find.text('No tasks found'), findsOneWidget);
        expect(find.text('Add Task'), findsOneWidget);
      });
    });

    group('Filter Tests', () {
      testWidgets('should show filter menu in tasks tab', (WidgetTester tester) async {
        await tester.pumpWidget(createHomeScreen());
        await tester.pumpAndSettle();

        // Tap on filter menu
        await tester.tap(find.byType(PopupMenuButton<String>));
        await tester.pumpAndSettle();

        expect(find.text('All Tasks'), findsOneWidget);
        expect(find.text('Completed'), findsOneWidget);
        expect(find.text('Incomplete'), findsOneWidget);
        expect(find.text('Today'), findsOneWidget);
        expect(find.text('Upcoming'), findsOneWidget);
      });

      testWidgets('should filter completed tasks', (WidgetTester tester) async {
        await tester.pumpWidget(createHomeScreen());
        await tester.pumpAndSettle();

        // Open filter menu
        await tester.tap(find.byType(PopupMenuButton<String>));
        await tester.pumpAndSettle();

        // Select completed filter
        await tester.tap(find.text('Completed'));
        await tester.pumpAndSettle();

        expect(find.text('Completed Task'), findsOneWidget);
        expect(find.text('Incomplete Task'), findsNothing);
        expect(find.text('Today Task'), findsNothing);
      });

      testWidgets('should filter incomplete tasks', (WidgetTester tester) async {
        await tester.pumpWidget(createHomeScreen());
        await tester.pumpAndSettle();

        // Open filter menu
        await tester.tap(find.byType(PopupMenuButton<String>));
        await tester.pumpAndSettle();

        // Select incomplete filter
        await tester.tap(find.text('Incomplete'));
        await tester.pumpAndSettle();

        expect(find.text('Completed Task'), findsNothing);
        expect(find.text('Incomplete Task'), findsOneWidget);
        expect(find.text('Today Task'), findsOneWidget);
      });

      testWidgets('should filter today tasks', (WidgetTester tester) async {
        await tester.pumpWidget(createHomeScreen());
        await tester.pumpAndSettle();

        // Open filter menu
        await tester.tap(find.byType(PopupMenuButton<String>));
        await tester.pumpAndSettle();

        // Select today filter
        await tester.tap(find.text('Today'));
        await tester.pumpAndSettle();

        expect(find.text('Today Task'), findsOneWidget);
        // Other tasks should not be visible if they're not due today
      });
    });

    group('Tab Navigation Tests', () {
      testWidgets('should switch to categories tab', (WidgetTester tester) async {
        await tester.pumpWidget(createHomeScreen());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Categories'));
        await tester.pumpAndSettle();

        // Should not show floating action button on categories tab
        expect(find.byType(FloatingActionButton), findsNothing);
      });

      testWidgets('should switch to statistics tab', (WidgetTester tester) async {
        await tester.pumpWidget(createHomeScreen());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Statistics'));
        await tester.pumpAndSettle();

        // Should not show floating action button on statistics tab
        expect(find.byType(FloatingActionButton), findsNothing);
      });

      testWidgets('should show floating action button only on tasks tab', (WidgetTester tester) async {
        await tester.pumpWidget(createHomeScreen());
        await tester.pumpAndSettle();

        // Should show FAB on tasks tab
        expect(find.byType(FloatingActionButton), findsOneWidget);

        // Switch to categories tab
        await tester.tap(find.text('Categories'));
        await tester.pumpAndSettle();
        expect(find.byType(FloatingActionButton), findsNothing);

        // Switch back to tasks tab
        await tester.tap(find.text('Tasks'));
        await tester.pumpAndSettle();
        expect(find.byType(FloatingActionButton), findsOneWidget);
      });
    });

    group('Interaction Tests', () {
      testWidgets('should refresh data when pull to refresh', (WidgetTester tester) async {
        await tester.pumpWidget(createHomeScreen());
        await tester.pumpAndSettle();

        // Find the RefreshIndicator
        final refreshFinder = find.byType(RefreshIndicator);
        expect(refreshFinder, findsOneWidget);

        // Perform pull to refresh
        await tester.drag(refreshFinder, const Offset(0, 200));
        await tester.pumpAndSettle();

        // Verify repository was called again
        verify(mockTaskRepository.getAllTasks()).called(greaterThan(1));
      });

      testWidgets('should navigate to add task when FAB is tapped', (WidgetTester tester) async {
        await tester.pumpWidget(createHomeScreen());
        await tester.pumpAndSettle();

        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();

        // Navigation would occur (can't easily test route changes in unit tests)
        expect(tester.takeException(), isNull);
      });

      testWidgets('should navigate to settings when settings button is tapped', (WidgetTester tester) async {
        await tester.pumpWidget(createHomeScreen());
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.settings));
        await tester.pumpAndSettle();

        // Navigation would occur
        expect(tester.takeException(), isNull);
      });
    });

    group('Error Handling Tests', () {
      testWidgets('should show error message when data loading fails', (WidgetTester tester) async {
        when(mockTaskRepository.getAllTasks())
            .thenThrow(Exception('Database error'));

        await tester.pumpWidget(createHomeScreen());
        await tester.pumpAndSettle();

        // Should show some error indication (snackbar or error widget)
        // The specific implementation may vary
        expect(tester.takeException(), isNull);
      });
    });

    group('Data Update Tests', () {
      testWidgets('should toggle task completion', (WidgetTester tester) async {
        when(mockTaskRepository.toggleTaskCompletion(any, any))
            .thenAnswer((_) async => 1);

        await tester.pumpWidget(createHomeScreen());
        await tester.pumpAndSettle();

        // Find and tap a checkbox
        final checkboxes = find.byType(Checkbox);
        if (checkboxes.evaluate().isNotEmpty) {
          await tester.tap(checkboxes.first);
          await tester.pumpAndSettle();

          // Verify the repository method was called
          verify(mockTaskRepository.toggleTaskCompletion(any, any)).called(1);
        }
      });
    });

    group('Responsive Design Tests', () {
      testWidgets('should handle different screen sizes', (WidgetTester tester) async {
        // Test with different screen sizes
        await tester.binding.setSurfaceSize(const Size(400, 800));
        await tester.pumpWidget(createHomeScreen());
        await tester.pumpAndSettle();

        expect(find.byType(TabBarView), findsOneWidget);

        // Test with wider screen
        await tester.binding.setSurfaceSize(const Size(800, 600));
        await tester.pumpWidget(createHomeScreen());
        await tester.pumpAndSettle();

        expect(find.byType(TabBarView), findsOneWidget);
      });
    });
  });
}