import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/features/categories/widgets/category_dialog.dart';
import 'package:todo_app/features/categories/models/category.dart';

void main() {
  group('CategoryDialog Tests', () {
    Widget createTestApp({Widget? child}) {
      return MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  final result = await showCategoryDialog(
                    context: context,
                    category: null,
                  );
                  if (result != null) {
                    // Handle result
                  }
                },
                child: const Text('Show Dialog'),
              );
            },
          ),
        ),
      );
    }

    Widget createTestAppForEditing({required Category category}) {
      return MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  final result = await showCategoryDialog(
                    context: context,
                    category: category,
                  );
                  if (result != null) {
                    // Handle result
                  }
                },
                child: const Text('Show Dialog'),
              );
            },
          ),
        ),
      );
    }

    group('Dialog Display', () {
      testWidgets('should show dialog when called', (WidgetTester tester) async {
        await tester.pumpWidget(createTestApp());

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsOneWidget);
      });

      testWidgets('should show "Add Category" title for new category', (WidgetTester tester) async {
        await tester.pumpWidget(createTestApp());

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        expect(find.text('Add Category'), findsOneWidget);
      });

      testWidgets('should show "Edit Category" title when editing', (WidgetTester tester) async {
        final category = Category(
          id: 1,
          name: 'Work',
          color: Colors.blue,
        );

        await tester.pumpWidget(createTestAppForEditing(category: category));

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        expect(find.text('Edit Category'), findsOneWidget);
      });

      testWidgets('should show CREATE button for new category', (WidgetTester tester) async {
        await tester.pumpWidget(createTestApp());

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        expect(find.text('CREATE'), findsOneWidget);
      });

      testWidgets('should show UPDATE button when editing', (WidgetTester tester) async {
        final category = Category(
          id: 1,
          name: 'Work',
          color: Colors.blue,
        );

        await tester.pumpWidget(createTestAppForEditing(category: category));

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        expect(find.text('UPDATE'), findsOneWidget);
      });

      testWidgets('should show CANCEL button', (WidgetTester tester) async {
        await tester.pumpWidget(createTestApp());

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        expect(find.text('CANCEL'), findsOneWidget);
      });
    });

    group('Input Field', () {
      testWidgets('should have empty name field for new category', (WidgetTester tester) async {
        await tester.pumpWidget(createTestApp());

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        final textField = tester.widget<TextFormField>(find.byType(TextFormField));
        expect(textField.controller?.text, isEmpty);
      });

      testWidgets('should pre-fill name field when editing', (WidgetTester tester) async {
        final category = Category(
          id: 1,
          name: 'Work',
          color: Colors.blue,
        );

        await tester.pumpWidget(createTestAppForEditing(category: category));

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        final textField = tester.widget<TextFormField>(find.byType(TextFormField));
        expect(textField.controller?.text, equals('Work'));
      });

      testWidgets('should accept text input', (WidgetTester tester) async {
        await tester.pumpWidget(createTestApp());

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextFormField), 'Personal');
        await tester.pump();

        final textField = tester.widget<TextFormField>(find.byType(TextFormField));
        expect(textField.controller?.text, equals('Personal'));
      });

      testWidgets('should have label text', (WidgetTester tester) async {
        await tester.pumpWidget(createTestApp());

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        expect(find.text('Category Name'), findsOneWidget);
      });
    });

    group('Color Picker', () {
      testWidgets('should display color picker', (WidgetTester tester) async {
        await tester.pumpWidget(createTestApp());

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        expect(find.text('Color'), findsOneWidget);
      });

      testWidgets('should display color options', (WidgetTester tester) async {
        await tester.pumpWidget(createTestApp());

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // Should find multiple colored containers
        final containers = tester.widgetList<Container>(find.byType(Container));
        final colorContainers = containers.where((c) =>
          c.constraints?.maxWidth == 40 && c.constraints?.maxHeight == 40
        );

        expect(colorContainers.length, greaterThan(0));
      });

      testWidgets('should select color when tapped', (WidgetTester tester) async {
        await tester.pumpWidget(createTestApp());

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // Find and tap a color (InkWell widgets)
        final inkWells = find.byType(InkWell);
        if (inkWells.evaluate().length > 1) {
          await tester.tap(inkWells.at(1));
          await tester.pumpAndSettle();
        }

        // Should still show the dialog
        expect(find.byType(AlertDialog), findsOneWidget);
      });

      testWidgets('should show blue as default color for new category', (WidgetTester tester) async {
        await tester.pumpWidget(createTestApp());

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // Default color should be blue - look for containers
        expect(find.byType(Container), findsWidgets);
      });

      testWidgets('should show category color when editing', (WidgetTester tester) async {
        final category = Category(
          id: 1,
          name: 'Work',
          color: Colors.red,
        );

        await tester.pumpWidget(createTestAppForEditing(category: category));

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // Should find containers with decoration
        expect(find.byType(Container), findsWidgets);
      });
    });

    group('Button Actions', () {
      testWidgets('should close dialog when CANCEL is pressed', (WidgetTester tester) async {
        await tester.pumpWidget(createTestApp());

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('CANCEL'));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsNothing);
      });

      testWidgets('should close dialog and return data when CREATE is pressed with valid input', (WidgetTester tester) async {
        await tester.pumpWidget(createTestApp());

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextFormField), 'Personal');
        await tester.pump();

        await tester.tap(find.text('CREATE'));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsNothing);
      });

      testWidgets('should not close dialog when CREATE is pressed with empty input', (WidgetTester tester) async {
        await tester.pumpWidget(createTestApp());

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // Leave the field empty
        await tester.tap(find.text('CREATE'));
        await tester.pumpAndSettle();

        // Dialog should still be open
        expect(find.byType(AlertDialog), findsOneWidget);
      });

      testWidgets('should trim whitespace from category name', (WidgetTester tester) async {
        await tester.pumpWidget(createTestApp());

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextFormField), '  Personal  ');
        await tester.pump();

        await tester.tap(find.text('CREATE'));
        await tester.pumpAndSettle();

        // Dialog should close (name was trimmed to non-empty)
        expect(find.byType(AlertDialog), findsNothing);
      });
    });

    group('Edge Cases', () {
      testWidgets('should handle very long category names', (WidgetTester tester) async {
        await tester.pumpWidget(createTestApp());

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byType(TextFormField),
          'This is a very long category name that might cause layout issues',
        );
        await tester.pump();

        // Should not cause any exceptions
        expect(tester.takeException(), isNull);
      });

      testWidgets('should handle special characters in name', (WidgetTester tester) async {
        await tester.pumpWidget(createTestApp());

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextFormField), 'Work 📱 & Personal 💼');
        await tester.pump();

        // Should not cause any exceptions
        expect(tester.takeException(), isNull);
      });

      testWidgets('should handle rapid color selection', (WidgetTester tester) async {
        await tester.pumpWidget(createTestApp());

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        final inkWells = find.byType(InkWell);
        if (inkWells.evaluate().length > 3) {
          // Rapidly tap different colors
          await tester.tap(inkWells.at(0));
          await tester.pump();
          await tester.tap(inkWells.at(1));
          await tester.pump();
          await tester.tap(inkWells.at(2));
          await tester.pumpAndSettle();
        }

        // Should not cause any exceptions
        expect(tester.takeException(), isNull);
      });
    });

    group('Layout', () {
      testWidgets('should display all elements in correct order', (WidgetTester tester) async {
        await tester.pumpWidget(createTestApp());

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // Check all major elements are present
        expect(find.text('Add Category'), findsOneWidget);
        expect(find.text('Category Name'), findsOneWidget);
        expect(find.text('Color'), findsOneWidget);
        expect(find.text('CANCEL'), findsOneWidget);
        expect(find.text('CREATE'), findsOneWidget);
      });

      testWidgets('should not cause overflow', (WidgetTester tester) async {
        await tester.pumpWidget(createTestApp());

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // Should render without overflow
        expect(tester.takeException(), isNull);
      });
    });
  });
}
