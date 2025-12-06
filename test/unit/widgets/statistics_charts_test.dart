import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/features/statistics/widgets/completion_chart.dart';
import 'package:todo_app/features/statistics/widgets/priority_chart.dart';
import 'package:todo_app/features/statistics/widgets/category_chart.dart';
import 'package:todo_app/features/categories/models/category.dart';

void main() {
  Widget createTestApp({required Widget child}) {
    return MaterialApp(
      home: Scaffold(
        body: child,
      ),
    );
  }

  group('CompletionChart Tests', () {
    testWidgets('should display title', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: CompletionChart(
            stats: {'Completed': 5, 'Incomplete': 3},
          ),
        ),
      );

      expect(find.text('Task Completion'), findsOneWidget);
    });

    testWidgets('should display chart with data', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: CompletionChart(
            stats: {'Completed': 5, 'Incomplete': 3},
          ),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
      expect(find.text('Task Completion'), findsOneWidget);
    });

    testWidgets('should show "No data available" when stats are empty', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: CompletionChart(
            stats: {'Completed': 0, 'Incomplete': 0},
          ),
        ),
      );

      expect(find.text('No data available'), findsOneWidget);
    });

    testWidgets('should handle only completed tasks', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: CompletionChart(
            stats: {'Completed': 10, 'Incomplete': 0},
          ),
        ),
      );

      expect(find.text('Task Completion'), findsOneWidget);
    });

    testWidgets('should handle only incomplete tasks', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: CompletionChart(
            stats: {'Completed': 0, 'Incomplete': 8},
          ),
        ),
      );

      expect(find.text('Task Completion'), findsOneWidget);
    });

    testWidgets('should handle missing stats keys', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: CompletionChart(
            stats: {},
          ),
        ),
      );

      expect(find.text('No data available'), findsOneWidget);
    });

    testWidgets('should handle large numbers', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: CompletionChart(
            stats: {'Completed': 1000, 'Incomplete': 500},
          ),
        ),
      );

      expect(find.text('Task Completion'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('should render without overflow', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: CompletionChart(
            stats: {'Completed': 25, 'Incomplete': 75},
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('PriorityChart Tests', () {
    testWidgets('should display title', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: PriorityChart(
            stats: {'High': 5, 'Medium': 3, 'Low': 2},
          ),
        ),
      );

      expect(find.text('Tasks by Priority'), findsOneWidget);
    });

    testWidgets('should display chart with data', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: PriorityChart(
            stats: {'High': 5, 'Medium': 3, 'Low': 2},
          ),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
      expect(find.text('Tasks by Priority'), findsOneWidget);
    });

    testWidgets('should show "No data available" when stats are empty', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: PriorityChart(
            stats: {'High': 0, 'Medium': 0, 'Low': 0},
          ),
        ),
      );

      expect(find.text('No data available'), findsOneWidget);
    });

    testWidgets('should handle only high priority tasks', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: PriorityChart(
            stats: {'High': 10, 'Medium': 0, 'Low': 0},
          ),
        ),
      );

      expect(find.text('Tasks by Priority'), findsOneWidget);
    });

    testWidgets('should handle only medium priority tasks', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: PriorityChart(
            stats: {'High': 0, 'Medium': 8, 'Low': 0},
          ),
        ),
      );

      expect(find.text('Tasks by Priority'), findsOneWidget);
    });

    testWidgets('should handle only low priority tasks', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: PriorityChart(
            stats: {'High': 0, 'Medium': 0, 'Low': 6},
          ),
        ),
      );

      expect(find.text('Tasks by Priority'), findsOneWidget);
    });

    testWidgets('should handle missing stats keys', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: PriorityChart(
            stats: {},
          ),
        ),
      );

      expect(find.text('No data available'), findsOneWidget);
    });

    testWidgets('should handle large numbers', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: PriorityChart(
            stats: {'High': 100, 'Medium': 200, 'Low': 150},
          ),
        ),
      );

      expect(find.text('Tasks by Priority'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('should render without overflow', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: PriorityChart(
            stats: {'High': 25, 'Medium': 15, 'Low': 10},
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('should handle unequal distribution', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: PriorityChart(
            stats: {'High': 50, 'Medium': 2, 'Low': 1},
          ),
        ),
      );

      expect(find.text('Tasks by Priority'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('CategoryChart Tests', () {
    final testCategories = [
      Category(id: 1, name: 'Work', color: Colors.blue),
      Category(id: 2, name: 'Personal', color: Colors.green),
      Category(id: 3, name: 'Shopping', color: Colors.orange),
    ];

    testWidgets('should display title', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: CategoryChart(
            stats: {'Work': 5, 'Personal': 3},
            categories: testCategories,
          ),
        ),
      );

      expect(find.text('Tasks by Category'), findsOneWidget);
    });

    testWidgets('should display chart with data', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: CategoryChart(
            stats: {'Work': 5, 'Personal': 3, 'Shopping': 2},
            categories: testCategories,
          ),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
      expect(find.text('Tasks by Category'), findsOneWidget);
    });

    testWidgets('should show "No data available" when stats are empty', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: CategoryChart(
            stats: {},
            categories: testCategories,
          ),
        ),
      );

      expect(find.text('No data available'), findsOneWidget);
    });

    testWidgets('should handle single category', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: CategoryChart(
            stats: {'Work': 15},
            categories: testCategories,
          ),
        ),
      );

      expect(find.text('Tasks by Category'), findsOneWidget);
    });

    testWidgets('should handle multiple categories', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: CategoryChart(
            stats: {
              'Work': 10,
              'Personal': 8,
              'Shopping': 5,
            },
            categories: testCategories,
          ),
        ),
      );

      expect(find.text('Tasks by Category'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('should handle empty categories list', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: CategoryChart(
            stats: {'Work': 5},
            categories: [],
          ),
        ),
      );

      expect(find.text('Tasks by Category'), findsOneWidget);
    });

    testWidgets('should handle category not in categories list', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: CategoryChart(
            stats: {'UnknownCategory': 5},
            categories: testCategories,
          ),
        ),
      );

      expect(find.text('Tasks by Category'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('should handle large numbers', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: CategoryChart(
            stats: {
              'Work': 500,
              'Personal': 300,
              'Shopping': 200,
            },
            categories: testCategories,
          ),
        ),
      );

      expect(find.text('Tasks by Category'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('should render without overflow', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: CategoryChart(
            stats: {
              'Work': 25,
              'Personal': 15,
              'Shopping': 10,
            },
            categories: testCategories,
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('should handle many categories', (WidgetTester tester) async {
      final manyCategories = List.generate(
        10,
        (index) => Category(
          id: index,
          name: 'Category $index',
          color: Colors.primaries[index % Colors.primaries.length],
        ),
      );

      final stats = {
        for (var i = 0; i < manyCategories.length; i++)
          manyCategories[i].name: (i + 1) * 5
      };

      await tester.pumpWidget(
        createTestApp(
          child: CategoryChart(
            stats: stats,
            categories: manyCategories,
          ),
        ),
      );

      expect(find.text('Tasks by Category'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('should handle unequal distribution', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: CategoryChart(
            stats: {
              'Work': 100,
              'Personal': 2,
              'Shopping': 1,
            },
            categories: testCategories,
          ),
        ),
      );

      expect(find.text('Tasks by Category'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Chart Layout Tests', () {
    testWidgets('CompletionChart should have proper card structure', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: CompletionChart(
            stats: {'Completed': 5, 'Incomplete': 3},
          ),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
      expect(find.byType(Padding), findsWidgets);
    });

    testWidgets('PriorityChart should have proper card structure', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: PriorityChart(
            stats: {'High': 5, 'Medium': 3, 'Low': 2},
          ),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
      expect(find.byType(Padding), findsWidgets);
    });

    testWidgets('CategoryChart should have proper card structure', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: CategoryChart(
            stats: {'Work': 5},
            categories: [
              Category(id: 1, name: 'Work', color: Colors.blue),
            ],
          ),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
      expect(find.byType(Padding), findsWidgets);
    });
  });

  group('Edge Cases', () {
    testWidgets('should handle zero values gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: Column(
            children: [
              CompletionChart(stats: {'Completed': 0, 'Incomplete': 0}),
              PriorityChart(stats: {'High': 0, 'Medium': 0, 'Low': 0}),
              CategoryChart(stats: {}, categories: []),
            ],
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('should handle negative values gracefully', (WidgetTester tester) async {
      // While negative values don't make sense for task counts,
      // the chart should handle them without crashing
      await tester.pumpWidget(
        createTestApp(
          child: CompletionChart(
            stats: {'Completed': -5, 'Incomplete': 3},
          ),
        ),
      );

      // Should not crash
      expect(tester.takeException(), isNull);
    });

    testWidgets('should handle very long category names', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: CategoryChart(
            stats: {
              'This is a very long category name that might cause issues': 5,
            },
            categories: [
              Category(
                id: 1,
                name: 'This is a very long category name that might cause issues',
                color: Colors.blue,
              ),
            ],
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
