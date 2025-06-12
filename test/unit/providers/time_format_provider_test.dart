import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo_app/core/providers/time_format_provider.dart';

@GenerateMocks([SharedPreferences])
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

    group('Multiple Instances', () {
      test('should maintain same state across instances', () async {
        SharedPreferences.setMockInitialValues({});
        
        final provider1 = TimeFormatProvider();
        final provider2 = TimeFormatProvider();
        
        await provider1.init();
        await provider2.init();
        
        await provider1.setTimeFormat(TimeFormat.american);
        
        // Provider2 should reflect the change after re-initialization
        await provider2.init();
        expect(provider2.timeFormat, equals(TimeFormat.american));
      });
    });

    group('Listener Management', () {
      test('should handle multiple listeners', () async {
        SharedPreferences.setMockInitialValues({});
        await provider.init();
        
        int listener1CallCount = 0;
        int listener2CallCount = 0;
        
        void listener1() => listener1CallCount++;
        void listener2() => listener2CallCount++;
        
        provider.addListener(listener1);
        provider.addListener(listener2);
        
        await provider.setTimeFormat(TimeFormat.american);
        
        expect(listener1CallCount, equals(1));
        expect(listener2CallCount, equals(1));
        
        // Remove one listener
        provider.removeListener(listener1);
        
        await provider.setTimeFormat(TimeFormat.european);
        
        expect(listener1CallCount, equals(1)); // Should not increase
        expect(listener2CallCount, equals(2)); // Should increase
      });

      test('should handle listener removal', () async {
        SharedPreferences.setMockInitialValues({});
        await provider.init();
        
        int listenerCallCount = 0;
        void listener() => listenerCallCount++;
        
        provider.addListener(listener);
        await provider.setTimeFormat(TimeFormat.american);
        expect(listenerCallCount, equals(1));
        
        provider.removeListener(listener);
        await provider.setTimeFormat(TimeFormat.european);
        expect(listenerCallCount, equals(1)); // Should not increase
      });
    });

    group('Error Handling', () {
      test('should handle SharedPreferences errors gracefully', () async {
        // This test ensures that even if SharedPreferences fails,
        // the provider still works with default values
        
        // We can't easily mock SharedPreferences to throw errors in this setup,
        // but we can ensure the provider handles missing data gracefully
        SharedPreferences.setMockInitialValues({
          'time_format_key': 'invalid_value',
        });
        
        await provider.init();
        
        // Should fall back to default
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