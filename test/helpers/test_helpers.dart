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

  /// Simulates device back button press
  static Future<void> simulateBackButton(WidgetTester tester) async {
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      'flutter/navigation',
      null,
      (data) {},
    );
  }

  /// Waits for all animations and async operations to complete
  static Future<void> pumpAndSettleAll(WidgetTester tester) async {
    await tester.pumpAndSettle(const Duration(seconds: 10));
  }

  /// Finds text containing a substring (case insensitive)
  static Finder findTextContaining(String substring) {
    return find.byWidgetPredicate((widget) {
      if (widget is Text) {
        return widget.data?.toLowerCase().contains(substring.toLowerCase()) == true;
      }
      return false;
    });
  }

  /// Finds widget by key string
  static Finder findByKeyString(String keyString) {
    return find.byKey(Key(keyString));
  }

  /// Scrolls until a widget is visible
  static Future<void> scrollUntilVisible(
    WidgetTester tester,
    Finder finder,
    Finder scrollable, {
    double delta = 100.0,
  }) async {
    while (finder.evaluate().isEmpty) {
      await tester.drag(scrollable, Offset(0, -delta));
      await tester.pump();
    }
  }

  /// Enters text in a TextField
  static Future<void> enterText(
    WidgetTester tester,
    Finder finder,
    String text,
  ) async {
    await tester.tap(finder);
    await tester.enterText(finder, text);
    await tester.pump();
  }

  /// Taps and waits for settling
  static Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pumpAndSettle();
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

  /// Verifies that no exceptions occurred during the test
  static void verifyNoExceptions(WidgetTester tester) {
    expect(tester.takeException(), isNull);
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