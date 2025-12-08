import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_app/core/widgets/models/widget_config.dart';
import 'package:todo_app/core/widgets/services/widget_service.dart';
import 'package:todo_app/core/logger/logger_service.dart';

/// Provider for WidgetService singleton
final widgetServiceProvider = Provider<WidgetService>((ref) {
  return WidgetService();
});

/// Provider for checking if widgets are supported on this platform
final widgetSupportedProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(widgetServiceProvider);
  return await service.isWidgetSupported();
});

/// Provider for checking if security is enabled (widgets disabled when password protection is on)
final widgetSecurityEnabledProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(widgetServiceProvider);
  return await service.isSecurityEnabled();
});

/// State notifier for managing widget configurations
class WidgetConfigNotifier extends StateNotifier<AsyncValue<List<WidgetConfig>>> {
  WidgetConfigNotifier(this._widgetService, this._logger) : super(const AsyncValue.loading()) {
    loadWidgets();
  }

  final WidgetService _widgetService;
  final LoggerService _logger;

  /// Load all widget configurations from database
  Future<void> loadWidgets() async {
    state = const AsyncValue.loading();
    try {
      await _logger.logInfo('[WidgetProvider] Loading widget configurations');
      final configs = await _widgetService.getAllWidgetConfigs();
      state = AsyncValue.data(configs);
      await _logger.logInfo('[WidgetProvider] Loaded ${configs.length} widget(s)');
    } catch (error, stackTrace) {
      await _logger.logError('[WidgetProvider] Error loading widgets', error, stackTrace);
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Create a new widget configuration
  Future<void> createWidget(WidgetConfig config) async {
    try {
      await _logger.logInfo('[WidgetProvider] Creating widget: ${config.name}');
      await _widgetService.createWidget(config);
      await loadWidgets(); // Reload to get updated list
    } catch (error, stackTrace) {
      await _logger.logError('[WidgetProvider] Error creating widget', error, stackTrace);
      rethrow;
    }
  }

  /// Update an existing widget configuration
  Future<void> updateWidget(int widgetId) async {
    try {
      await _logger.logInfo('[WidgetProvider] Updating widget ID: $widgetId');
      await _widgetService.updateWidget(widgetId);
      await loadWidgets(); // Reload to get updated list
    } catch (error, stackTrace) {
      await _logger.logError('[WidgetProvider] Error updating widget', error, stackTrace);
      rethrow;
    }
  }

  /// Delete a widget configuration
  Future<void> deleteWidget(int widgetId) async {
    try {
      await _logger.logInfo('[WidgetProvider] Deleting widget ID: $widgetId');
      await _widgetService.deleteWidget(widgetId);
      await loadWidgets(); // Reload to get updated list
    } catch (error, stackTrace) {
      await _logger.logError('[WidgetProvider] Error deleting widget', error, stackTrace);
      rethrow;
    }
  }

  /// Update all widgets with latest data
  Future<void> updateAllWidgets() async {
    try {
      await _logger.logInfo('[WidgetProvider] Updating all widgets');
      await _widgetService.updateAllWidgets();
      // No need to reload configs, just refresh widget display
    } catch (error, stackTrace) {
      await _logger.logError('[WidgetProvider] Error updating all widgets', error, stackTrace);
      rethrow;
    }
  }

  /// Force immediate widget update
  Future<void> forceWidgetUpdate() async {
    try {
      await _logger.logInfo('[WidgetProvider] Force updating widgets');
      await _widgetService.forceWidgetUpdate();
    } catch (error, stackTrace) {
      await _logger.logError('[WidgetProvider] Error force updating widgets', error, stackTrace);
      rethrow;
    }
  }
}

/// Provider for widget configuration list with reactive state management
final widgetConfigProvider = StateNotifierProvider<WidgetConfigNotifier, AsyncValue<List<WidgetConfig>>>((ref) {
  final service = ref.watch(widgetServiceProvider);
  final logger = LoggerService();
  return WidgetConfigNotifier(service, logger);
});

/// Provider to get a specific widget configuration by ID
final widgetConfigByIdProvider = Provider.family<WidgetConfig?, int>((ref, widgetId) {
  final widgetsAsync = ref.watch(widgetConfigProvider);
  return widgetsAsync.whenOrNull(
    data: (widgets) => widgets.firstWhere(
      (widget) => widget.id == widgetId,
      orElse: () => WidgetConfig(name: '', size: WidgetSize.medium),
    ),
  );
});

/// Provider for widget count
final widgetCountProvider = Provider<int>((ref) {
  final widgetsAsync = ref.watch(widgetConfigProvider);
  return widgetsAsync.whenOrNull(data: (widgets) => widgets.length) ?? 0;
});
