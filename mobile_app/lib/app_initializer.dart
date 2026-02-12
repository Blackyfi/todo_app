import 'package:todo_app/core/logger/logger_service.dart';
import 'package:todo_app/core/notifications/notification_service.dart';
import 'package:todo_app/core/providers/time_format_provider.dart';
import 'package:todo_app/core/widgets/services/widget_service.dart';

class AppInitializer {
  static bool _isInitialized = false;
  
  Future<void> initialize(
    LoggerService loggerService,
    NotificationService notificationService,
    TimeFormatProvider timeFormatProvider,
  ) async {
    try {
      if (_isInitialized) {
        await loggerService.logInfo('Application already initialized, skipping');
        return;
      }
      
      await loggerService.logInfo('===== Application Started =====');
      await _initializeServices(
        loggerService, 
        notificationService, 
        timeFormatProvider,
      );
      
      _isInitialized = true;
    } catch (e, stackTrace) {
      await loggerService.logError('Error during app initialization', e, stackTrace);
    }
  }

  Future<void> _initializeServices(
    LoggerService loggerService,
    NotificationService notificationService,
    TimeFormatProvider timeFormatProvider,
  ) async {
    await loggerService.logInfo('Application initialization started');
    
    await notificationService.init();
    await loggerService.logInfo('Notification service initialized');
    
    await timeFormatProvider.init();
    await loggerService.logInfo('Time format provider initialized');
    
    final widgetService = WidgetService();
    await widgetService.init();
    await loggerService.logInfo('Widget service initialized');
    
    await notificationService.requestNotificationPermission();
    await loggerService.logInfo('Notification permissions requested');
    
    await loggerService.logInfo('Application initialized successfully');
  }
}