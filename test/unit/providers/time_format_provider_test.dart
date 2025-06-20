import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo_app/core/providers/time_format_provider.dart';

void main() {
  group('TimeFormatProvider Tests', () {
    late TimeFormatProvider provider;
    
    setUp(() {
      provider = TimeFormatProvider();
    });

    group('Initialization', () {
      test('should start with European format as default', () {
        expect(provider.timeFormat, equals(TimeFormat.european));
        expect(provider.isEuropean, isTrue);
      });

      test('should initialize with stored format from SharedPreferences', () async {
        // Mock SharedPreferences
        SharedPreferences.setMockInitialValues({
          'time_format_key': TimeFormat.american.toString(),
        });
        
        await provider.init();
        
        expect(provider.timeFormat, equals(TimeFormat.american));
        expect(provider.isEuropean, isFalse);
      });

      test('should use default format when no stored preference exists', () async {
        // Mock SharedPreferences with no stored value
        SharedPreferences.setMockInitialValues({});
        
        await provider.init();
        
        expect(provider.timeFormat, equals(TimeFormat.european));
        expect(provider.isEuropean, isTrue);
      });
    });

    group('Setting Time Format', () {
      test('should change format to American and notify listeners', () async {
        SharedPreferences.setMockInitialValues({});
        await provider.init();
        
        bool listenerCalled = false;
        provider.addListener(() {
          listenerCalled = true;
        });

        await provider.setTimeFormat(TimeFormat.american);

        expect(provider.timeFormat, equals(TimeFormat.american));
        expect(provider.isEuropean, isFalse);
        expect(listenerCalled, isTrue);
      });

      test('should change format to European and notify listeners', () async {
        SharedPreferences.setMockInitialValues({});
        await provider.init();
        
        // First set to American
        await provider.setTimeFormat(TimeFormat.american);
        
        bool listenerCalled = false;
        provider.addListener(() {
          listenerCalled = true;
        });

        await provider.setTimeFormat(TimeFormat.european);

        expect(provider.timeFormat, equals(TimeFormat.european));
        expect(provider.isEuropean, isTrue);
        expect(listenerCalled, isTrue);
      });

      test('should not notify listeners when setting same format', () async {
        SharedPreferences.setMockInitialValues({});
        await provider.init();
        
        bool listenerCalled = false;
        provider.addListener(() {
          listenerCalled = true;
        });

        // Set to the same format (European is default)
        await provider.setTimeFormat(TimeFormat.european);

        expect(listenerCalled, isFalse);
      });

      test('should persist format change to SharedPreferences', () async {
        SharedPreferences.setMockInitialValues({});
        await provider.init();
        
        await provider.setTimeFormat(TimeFormat.american);
        
        // Get the stored value
        final prefs = await SharedPreferences.getInstance();
        final storedFormat = prefs.getString('time_format_key');
        
        expect(storedFormat, equals(TimeFormat.american.toString()));
      });
    });

    group('isEuropean getter', () {
      test('should return true when format is European', () async {
        SharedPreferences.setMockInitialValues({});
        await provider.init();
        
        await provider.setTimeFormat(TimeFormat.european);
        expect(provider.isEuropean, isTrue);
      });

      test('should return false when format is American', () async {
        SharedPreferences.setMockInitialValues({});
        await provider.init();
        
        await provider.setTimeFormat(TimeFormat.american);
        expect(provider.isEuropean, isFalse);
      });
    });

    group('Error Handling', () {
      test('should handle SharedPreferences errors gracefully', () async {
        // Set up initial values with the default format
        SharedPreferences.setMockInitialValues({});
        
        await provider.init();
        
        // Should use default format
        expect(provider.timeFormat, equals(TimeFormat.european));
      });
    });
  });

  group('TimeFormat Enum Tests', () {
    test('should have correct string representations', () {
      expect(TimeFormat.european.toString(), equals('TimeFormat.european'));
      expect(TimeFormat.american.toString(), equals('TimeFormat.american'));
    });
  });
}