import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:todo_app/core/widgets/models/widget_config.dart';
import 'package:todo_app/core/widgets/models/widget_theme.dart';

/// Enhanced widget service tests for new P0-P3 features
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Enhanced Widget Features Tests', () {
    group('Widget Sizes (P2)', () {
      test('should support all 5 widget sizes', () {
        expect(WidgetSize.values.length, equals(5));
        expect(WidgetSize.values, contains(WidgetSize.small));
        expect(WidgetSize.values, contains(WidgetSize.medium));
        expect(WidgetSize.values, contains(WidgetSize.large));
        expect(WidgetSize.values, contains(WidgetSize.extraLarge));
        expect(WidgetSize.values, contains(WidgetSize.wide));
      });

      test('should have correct size labels', () {
        expect(WidgetSize.small.label, equals('Small (2x2)'));
        expect(WidgetSize.medium.label, equals('Medium (4x2)'));
        expect(WidgetSize.large.label, equals('Large (4x4)'));
        expect(WidgetSize.extraLarge.label, equals('Extra Large (4x5)'));
        expect(WidgetSize.wide.label, equals('Wide (5x2)'));
      });

      test('should have correct recommended max tasks', () {
        expect(WidgetSize.small.recommendedMaxTasks, equals(2));
        expect(WidgetSize.medium.recommendedMaxTasks, equals(3));
        expect(WidgetSize.large.recommendedMaxTasks, equals(6));
        expect(WidgetSize.extraLarge.recommendedMaxTasks, equals(8));
        expect(WidgetSize.wide.recommendedMaxTasks, equals(4));
      });

      test('should have size descriptions', () {
        expect(WidgetSize.small.description, isNotEmpty);
        expect(WidgetSize.medium.description, isNotEmpty);
        expect(WidgetSize.large.description, isNotEmpty);
        expect(WidgetSize.extraLarge.description, contains('tall'));
        expect(WidgetSize.wide.description, contains('Wide'));
      });

      test('should have correct dimensions', () {
        expect(WidgetSize.small.size.width, equals(150));
        expect(WidgetSize.small.size.height, equals(150));

        expect(WidgetSize.medium.size.width, equals(300));
        expect(WidgetSize.medium.size.height, equals(150));

        expect(WidgetSize.large.size.width, equals(300));
        expect(WidgetSize.large.size.height, equals(300));

        expect(WidgetSize.extraLarge.size.width, equals(300));
        expect(WidgetSize.extraLarge.size.height, equals(375));

        expect(WidgetSize.wide.size.width, equals(375));
        expect(WidgetSize.wide.size.height, equals(150));
      });
    });

    group('Widget Themes (P2)', () {
      test('should create default themes', () {
        expect(WidgetTheme.light.name, equals('Light'));
        expect(WidgetTheme.dark.name, equals('Dark'));
        expect(WidgetTheme.materialYou.name, equals('Material You'));
        expect(WidgetTheme.minimal.name, equals('Minimal'));
      });

      test('should have correct color schemes', () {
        expect(WidgetColorScheme.values.length, equals(8));
        expect(WidgetColorScheme.values, contains(WidgetColorScheme.light));
        expect(WidgetColorScheme.values, contains(WidgetColorScheme.dark));
        expect(WidgetColorScheme.values, contains(WidgetColorScheme.materialYou));
        expect(WidgetColorScheme.values, contains(WidgetColorScheme.minimal));
        expect(WidgetColorScheme.values, contains(WidgetColorScheme.ocean));
        expect(WidgetColorScheme.values, contains(WidgetColorScheme.sunset));
        expect(WidgetColorScheme.values, contains(WidgetColorScheme.forest));
        expect(WidgetColorScheme.values, contains(WidgetColorScheme.custom));
      });

      test('should have correct text styles', () {
        expect(WidgetTextStyle.values.length, equals(4));
        expect(WidgetTextStyle.small.titleFontSize, equals(12.0));
        expect(WidgetTextStyle.normal.titleFontSize, equals(14.0));
        expect(WidgetTextStyle.large.titleFontSize, equals(16.0));
        expect(WidgetTextStyle.extraLarge.titleFontSize, equals(18.0));
      });

      test('should convert theme to map and back', () {
        final theme = WidgetTheme(
          name: 'Test Theme',
          colorScheme: WidgetColorScheme.ocean,
          textStyle: WidgetTextStyle.large,
          cornerRadius: 20.0,
          showShadow: false,
        );

        final map = theme.toMap();
        expect(map['name'], equals('Test Theme'));
        expect(map['colorScheme'], equals(WidgetColorScheme.ocean.index));
        expect(map['textStyle'], equals(WidgetTextStyle.large.index));
        expect(map['cornerRadius'], equals(20.0));
        expect(map['showShadow'], equals(0));

        final restoredTheme = WidgetTheme.fromMap(map);
        expect(restoredTheme.name, equals('Test Theme'));
        expect(restoredTheme.colorScheme, equals(WidgetColorScheme.ocean));
        expect(restoredTheme.textStyle, equals(WidgetTextStyle.large));
        expect(restoredTheme.cornerRadius, equals(20.0));
        expect(restoredTheme.showShadow, equals(false));
      });

      test('should copy theme with modifications', () {
        final original = WidgetTheme.light;

        final modified = original.copyWith(
          name: 'Modified Light',
          cornerRadius: 24.0,
        );

        expect(modified.name, equals('Modified Light'));
        expect(modified.cornerRadius, equals(24.0));
        expect(modified.colorScheme, equals(original.colorScheme));
        expect(modified.textStyle, equals(original.textStyle));
      });

      test('should have readable color scheme labels', () {
        expect(WidgetColorScheme.light.label, equals('Light'));
        expect(WidgetColorScheme.dark.label, equals('Dark'));
        expect(WidgetColorScheme.materialYou.label, equals('Material You'));
        expect(WidgetColorScheme.ocean.label, equals('Ocean Blue'));
        expect(WidgetColorScheme.sunset.label, equals('Sunset Orange'));
        expect(WidgetColorScheme.forest.label, equals('Forest Green'));
      });

      test('should have appropriate background colors', () {
        expect(WidgetColorScheme.light.backgroundColor.toARGB32(), isNonZero);
        expect(WidgetColorScheme.dark.backgroundColor.toARGB32(), isNonZero);
        expect(WidgetColorScheme.ocean.backgroundColor.toARGB32(), isNonZero);
      });

      test('should have appropriate text colors', () {
        expect(WidgetColorScheme.light.textColor.toARGB32(), isNonZero);
        expect(WidgetColorScheme.dark.textColor.toARGB32(), isNonZero);

        // Dark themes should have light text
        expect(WidgetColorScheme.dark.textColor.toARGB32(), equals(0xFFFFFFFF));
        expect(WidgetColorScheme.ocean.textColor.toARGB32(), equals(0xFFFFFFFF));
      });

      test('should have secondary text color with opacity', () {
        final primaryColor = WidgetColorScheme.light.textColor;
        final secondaryColor = WidgetColorScheme.light.secondaryTextColor;

        final primaryAlpha = (primaryColor.a * 255.0).round() & 0xff;
        final secondaryAlpha = (secondaryColor.a * 255.0).round() & 0xff;

        expect(secondaryAlpha, lessThan(primaryAlpha));
      });
    });

    group('Multiple Widget Support (P0)', () {
      test('should support widget-specific IDs', () {
        final config1 = WidgetConfig(
          id: 1,
          name: 'Widget 1',
          size: WidgetSize.small,
        );

        final config2 = WidgetConfig(
          id: 2,
          name: 'Widget 2',
          size: WidgetSize.large,
        );

        expect(config1.id, isNot(equals(config2.id)));
        expect(config1.name, isNot(equals(config2.name)));
      });

      test('should allow different configurations per widget', () {
        final widgets = [
          WidgetConfig(
            id: 1,
            name: 'Work Tasks',
            size: WidgetSize.medium,
            categoryFilter: 'Work',
            maxTasks: 5,
          ),
          WidgetConfig(
            id: 2,
            name: 'Personal Tasks',
            size: WidgetSize.small,
            categoryFilter: 'Personal',
            maxTasks: 3,
          ),
          WidgetConfig(
            id: 3,
            name: 'All Tasks',
            size: WidgetSize.large,
            categoryFilter: null,
            maxTasks: 10,
          ),
        ];

        expect(widgets.length, equals(3));
        expect(widgets[0].categoryFilter, equals('Work'));
        expect(widgets[1].categoryFilter, equals('Personal'));
        expect(widgets[2].categoryFilter, isNull);
      });
    });

    group('Widget Config Validation', () {
      test('should enforce max tasks limits', () {
        final config = WidgetConfig(
          name: 'Test',
          maxTasks: 20,
        );

        expect(config.maxTasks, lessThanOrEqualTo(20));
        expect(config.maxTasks, greaterThan(0));
      });

      test('should have sensible defaults', () {
        final config = WidgetConfig(name: 'Default Test');

        expect(config.size, equals(WidgetSize.medium));
        expect(config.showCompleted, isFalse);
        expect(config.showCategories, isTrue);
        expect(config.showPriority, isTrue);
        expect(config.maxTasks, equals(3));
      });

      test('should handle null category filter', () {
        final config = WidgetConfig(
          name: 'All Categories',
          categoryFilter: null,
        );

        expect(config.categoryFilter, isNull);
      });

      test('should preserve creation timestamp', () {
        final now = DateTime.now();
        final config = WidgetConfig(
          name: 'Timestamp Test',
          createdAt: now,
        );

        expect(config.createdAt, equals(now));
      });
    });

    group('Widget Size Compatibility', () {
      test('should serialize and deserialize all sizes', () {
        for (final size in WidgetSize.values) {
          final config = WidgetConfig(
            name: 'Test ${size.label}',
            size: size,
          );

          final map = config.toMap();
          final restored = WidgetConfig.fromMap(map);

          expect(restored.size, equals(size));
        }
      });
    });

    group('Theme Presets', () {
      test('should have Material You preset with correct properties', () {
        expect(WidgetTheme.materialYou.cornerRadius, equals(24.0));
        expect(WidgetTheme.materialYou.colorScheme, equals(WidgetColorScheme.materialYou));
      });

      test('should have Minimal preset with no shadows', () {
        expect(WidgetTheme.minimal.showShadow, isFalse);
        expect(WidgetTheme.minimal.textStyle, equals(WidgetTextStyle.small));
        expect(WidgetTheme.minimal.cornerRadius, equals(8.0));
      });

      test('should have Light and Dark theme defaults', () {
        expect(WidgetTheme.light.colorScheme, equals(WidgetColorScheme.light));
        expect(WidgetTheme.dark.colorScheme, equals(WidgetColorScheme.dark));
        expect(WidgetTheme.light.showShadow, isTrue);
        expect(WidgetTheme.dark.showShadow, isTrue);
      });
    });
  });
}
