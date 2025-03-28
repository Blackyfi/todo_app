import 'package:todo_app/core/logger/logger_service.dart';
import 'package:todo_app/core/notifications/notification_service.dart';
import 'package:todo_app/core/providers/time_format_provider.dart';

class AppInitializer {
  Future<void> initialize(
    LoggerService loggerService,
    NotificationService notificationService,
    TimeFormatProvider timeFormatProvider,
  ) async {
    try {
      await _initializeServices(
        loggerService, 
        notificationService, 
        timeFormatProvider,
      );
    } catch (e, stackTrace) {
      await loggerService.logError('Error during app initialization', e, stackTrace);
    }
  }

  Future<void> _initializeServices(
    LoggerService loggerService,
    NotificationService notificationService,
    TimeFormatProvider timeFormatProvider,
  ) async {
    await loggerService.init();
    await loggerService.logInfo('Application initialization started');
    
    await notificationService.init();
    await loggerService.logInfo('Notification service initialized');
    
    await timeFormatProvider.init();
    await loggerService.logInfo('Time format provider initialized');
    
    await loggerService.logInfo('Application initialized successfully');
  }
}