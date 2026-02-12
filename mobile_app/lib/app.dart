import 'package:flutter/material.dart' as mat;
import 'package:provider/provider.dart';
import 'package:todo_app/common/constants/app_constants.dart' as app_constants;
import 'package:todo_app/common/theme/app_theme.dart' as app_theme;
import 'package:todo_app/routes.dart' as routes;
import 'package:todo_app/core/notifications/notification_service.dart' as notification_service;
import 'package:todo_app/core/logger/logger_service.dart';
import 'package:todo_app/core/providers/time_format_provider.dart';
import 'package:todo_app/core/security/providers/security_provider.dart';
import 'package:todo_app/features/security/screens/unlock_screen.dart';
import 'package:todo_app/app_initializer.dart';
import 'package:todo_app/main.dart' show globalDataChangeNotifier;

class TodoApp extends mat.StatefulWidget {
  final mat.GlobalKey<mat.NavigatorState> navigatorKey;
  
  const TodoApp({super.key, required this.navigatorKey});

  @override
  mat.State<TodoApp> createState() => _TodoAppState();
}

class _TodoAppState extends mat.State<TodoApp> with mat.WidgetsBindingObserver {
  final _notificationService = notification_service.NotificationService();
  final _loggerService = LoggerService();
  final mat.ThemeMode _themeMode = mat.ThemeMode.system;
  final _timeFormatProvider = TimeFormatProvider();
  final _securityProvider = SecurityProvider();
  final _appInitializer = AppInitializer();
  bool _isUnlocked = false;

  @override
  void initState() {
    super.initState();

    // Add app lifecycle observer
    mat.WidgetsBinding.instance.addObserver(this);

    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _securityProvider.initialize();

    _appInitializer.initialize(
      _loggerService,
      _notificationService,
      _timeFormatProvider,
    );

    // Check if security is enabled and user needs to unlock
    if (_securityProvider.isSecurityEnabled && !_securityProvider.isAuthenticated) {
      // Don't set _isUnlocked to true, let the builder show unlock screen
      setState(() {});
    } else {
      setState(() => _isUnlocked = true);
    }
  }

  void _onUnlockSuccess() {
    setState(() => _isUnlocked = true);
  }

  @override
  void dispose() {
    mat.WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(mat.AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (state == mat.AppLifecycleState.resumed) {
      _loggerService.logInfo('App resumed at application level - triggering global data change notification');
      // Trigger global data change notification when app resumes
      globalDataChangeNotifier.value = !globalDataChangeNotifier.value;
    }
  }

  @override
  mat.Widget build(mat.BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _timeFormatProvider),
        ChangeNotifierProvider.value(value: _securityProvider),
      ],
      child: mat.MaterialApp(
        navigatorKey: widget.navigatorKey,
        title: app_constants.AppConstants.appName,
        theme: app_theme.AppTheme.lightTheme,
        darkTheme: app_theme.AppTheme.darkTheme,
        themeMode: _themeMode,
        onGenerateRoute: routes.AppRouter.generateRoute,
        initialRoute: app_constants.AppConstants.homeRoute,
        debugShowCheckedModeBanner: false,
        builder: (context, child) {
          // Show unlock screen if security is enabled and not authenticated
          if (!_isUnlocked) {
            return ChangeNotifierProvider.value(
              value: _securityProvider,
              child: _UnlockWrapper(
                onUnlockSuccess: _onUnlockSuccess,
              ),
            );
          }
          return child ?? const mat.SizedBox.shrink();
        },
      ),
    );
  }
}

/// Wrapper widget that shows the unlock screen and handles authentication
class _UnlockWrapper extends mat.StatelessWidget {
  final mat.VoidCallback onUnlockSuccess;

  const _UnlockWrapper({required this.onUnlockSuccess});

  @override
  mat.Widget build(mat.BuildContext context) {
    final securityProvider = context.watch<SecurityProvider>();

    // If user becomes authenticated through the unlock screen,
    // notify parent to rebuild with main app
    if (securityProvider.isAuthenticated) {
      mat.WidgetsBinding.instance.addPostFrameCallback((_) {
        onUnlockSuccess();
      });
    }

    return const UnlockScreen();
  }
}