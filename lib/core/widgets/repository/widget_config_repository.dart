import 'package:todo_app/core/database/database_helper.dart' as db_helper;
import 'package:todo_app/core/widgets/models/widget_config.dart';
import 'package:todo_app/core/logger/logger_service.dart';

class WidgetConfigRepository {
  final db_helper.DatabaseHelper _databaseHelper = db_helper.DatabaseHelper();
  final LoggerService _logger = LoggerService();

  Future<int> insertWidgetConfig(WidgetConfig config) async {
    try {
      final db = await _databaseHelper.database;
      final id = await db.insert('widgetConfigs', config.toMap());
      await _logger.logInfo('Widget config inserted: ID=$id, Name=${config.name}');
      return id;
    } catch (e, stackTrace) {
      await _logger.logError('Error inserting widget config', e, stackTrace);
      rethrow;
    }
  }

  Future<int> updateWidgetConfig(WidgetConfig config) async {
    try {
      final db = await _databaseHelper.database;
      
      await _logger.logInfo('=== UPDATING Widget Config ===');
      await _logger.logInfo('Updating widget ID: ${config.id}');
      await _logger.logInfo('New config: Name=${config.name}, Size=${config.size.label}, MaxTasks=${config.maxTasks}');
      await _logger.logInfo('Display options: ShowCompleted=${config.showCompleted}, ShowCategories=${config.showCategories}, ShowPriority=${config.showPriority}');
      
      final result = await db.update(
        'widgetConfigs',
        config.toMap(),
        where: 'id = ?',
        whereArgs: [config.id],
      );
      
      await _logger.logInfo('Widget config update result: Rows affected=$result');
      await _logger.logInfo('=== Widget Config Update Complete ===');
      
      return result;
    } catch (e, stackTrace) {
      await _logger.logError('Error updating widget config', e, stackTrace);
      rethrow;
    }
  }

  Future<int> deleteWidgetConfig(int id) async {
    try {
      final db = await _databaseHelper.database;
      final result = await db.delete(
        'widgetConfigs',
        where: 'id = ?',
        whereArgs: [id],
      );
      await _logger.logInfo('Widget config deleted: ID=$id');
      return result;
    } catch (e, stackTrace) {
      await _logger.logError('Error deleting widget config', e, stackTrace);
      rethrow;
    }
  }

  Future<WidgetConfig?> getWidgetConfig(int id) async {
    try {
      final db = await _databaseHelper.database;
      final maps = await db.query(
        'widgetConfigs',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (maps.isNotEmpty) {
        await _logger.logInfo('Widget config retrieved: ID=$id');
        return WidgetConfig.fromMap(maps.first);
      }
      
      await _logger.logWarning('Widget config not found: ID=$id');
      return null;
    } catch (e, stackTrace) {
      await _logger.logError('Error getting widget config', e, stackTrace);
      rethrow;
    }
  }

  Future<List<WidgetConfig>> getAllWidgetConfigs() async {
    try {
      final db = await _databaseHelper.database;
      final maps = await db.query('widgetConfigs', orderBy: 'createdAt DESC');

      final configs = List.generate(maps.length, (i) {
        return WidgetConfig.fromMap(maps[i]);
      });
      
      await _logger.logInfo('Retrieved all widget configs: Count=${configs.length}');
      return configs;
    } catch (e, stackTrace) {
      await _logger.logError('Error getting all widget configs', e, stackTrace);
      rethrow;
    }
  }
}