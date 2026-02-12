import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todo_app/core/providers/time_format_provider.dart';

/// Helper class providing common test utilities
class TestHelpers {
  /// Wraps a widget with MaterialApp for testing
  static Widget wrapWithMaterialApp(Widget child) {
    return MaterialApp(
      home: Scaffold(body: child),
    );
  }

  /// Wraps a widget with MaterialApp and providers for testing
  static Widget wrapWithProvidersAndMaterialApp(Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TimeFormatProvider()),
      ],
      child: MaterialApp(
        home: Scaffold(body: child),
      ),
    );
  }

  /// Creates a test MediaQuery with specified size
  static Widget wrapWithMediaQuery(Widget child, Size size) {
    return MediaQuery(
      data: MediaQueryData(size: size),
      child: child,
    );
  }

  /// Creates a test Theme wrapper
  static Widget wrapWithTheme(Widget child, {ThemeData? theme}) {
    return Theme(
      data: theme ?? ThemeData(),
      child: child,
    );
  }

  /// Creates a full test wrapper with MaterialApp, Theme, and MediaQuery
  static Widget createFullTestWrapper({
    required Widget child,
    Size? size,
    ThemeData? theme,
    List<ChangeNotifierProvider>? providers,
  }) {
    Widget wrappedChild = child;

    // Wrap with providers if provided
    if (providers != null && providers.isNotEmpty) {
      wrappedChild = MultiProvider(
        providers: providers,
        child: wrappedChild,
      );
    }

    // Wrap with MediaQuery if size is specified
    if (size != null) {
      wrappedChild = wrapWithMediaQuery(wrappedChild, size);
    }

    // Wrap with MaterialApp
    wrappedChild = MaterialApp(
      theme: theme,
      home: Scaffold(body: wrappedChild),
    );

    return wrappedChild;
  }

  /// Creates a navigator wrapper for testing navigation
  static Widget wrapWithNavigator(Widget child) {
    return MaterialApp(
      home: child,
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: Text(settings.name ?? 'Test Route')),
            body: const Center(child: Text('Test Route')),
          ),
        );
      },
    );
  }

  /// Creates a test DateTime that's always the same for consistent tests
  static DateTime createTestDateTime({
    int year = 2024,
    int month = 12,
    int day = 25,
    int hour = 14,
    int minute = 30,
  }) {
    return DateTime(year, month, day, hour, minute);
  }

  /// Creates a mock callback that tracks calls
  static MockCallback createMockCallback() {
    return MockCallback();
  }
}

/// Mock callback class for testing
class MockCallback {
  int callCount = 0;
  List<dynamic> arguments = [];
  
  void call([dynamic arg]) {
    callCount++;
    if (arg != null) {
      arguments.add(arg);
    }
  }
  
  void reset() {
    callCount = 0;
    arguments.clear();
  }
  
  bool get wasCalled => callCount > 0;
  bool get wasNotCalled => callCount == 0;
}