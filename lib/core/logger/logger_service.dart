import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:intl/intl.dart' as intl;

class LoggerService {
  static final LoggerService _instance = LoggerService._internal();
  
  factory LoggerService() => _instance;
  
  LoggerService._internal();
  
  late String _logFilePath;
  final _dateFormat = intl.DateFormat('yyyy-MM-dd HH:mm:ss');
  
  /// Initialize the logger and create the log file
  Future<void> init() async {
    try {
      final appDocDir = await path_provider.getApplicationDocumentsDirectory();
      final logDir = Directory('${appDocDir.path}/logs');
      
      // Create logs directory if it doesn't exist
      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }
      
      // Create a file name with the current date
      final now = DateTime.now();
      final fileName = 'app_log_${now.year}_${now.month}_${now.day}.log';
      _logFilePath = '${logDir.path}/$fileName';
      
      // Log app start
      await logInfo('===== Application Started =====');
    } catch (e) {
      // Print to console if there's an issue initializing the logger
      debugPrint('Error initializing logger: $e');
    }
  }
  
  /// Log an error with optional stack trace
  Future<void> logError(String message, [dynamic error, StackTrace? stackTrace]) async {
    final errorMessage = error != null ? '$message: $error' : message;
    await _writeToLogFile('ERROR', errorMessage);
    
    if (stackTrace != null) {
      await _writeToLogFile('STACK', stackTrace.toString());
    }
  }
  
  /// Log a warning message
  Future<void> logWarning(String message) async {
    await _writeToLogFile('WARNING', message);
  }
  
  /// Log an info message
  Future<void> logInfo(String message) async {
    await _writeToLogFile('INFO', message);
  }
  
  /// Write a message to the log file
  Future<void> _writeToLogFile(String level, String message) async {
    try {
      final file = File(_logFilePath);
      final timestamp = _dateFormat.format(DateTime.now());
      final logMessage = '[$timestamp] $level: $message\n';
      
      // Open file in append mode and write
      await file.writeAsString(logMessage, mode: FileMode.append);
    } catch (e) {
      // If we can't write to the log file, at least print to console
      debugPrint('Failed to write to log file: $e');
      debugPrint('Original message: [$level] $message');
    }
  }
  
  /// Get all log files
  Future<List<File>> getLogFiles() async {
    try {
      final appDocDir = await path_provider.getApplicationDocumentsDirectory();
      final logDir = Directory('${appDocDir.path}/logs');
      
      if (!await logDir.exists()) {
        return [];
      }
      
      final files = await logDir.list().where((entity) => 
        entity is File && entity.path.endsWith('.log')
      ).cast<File>().toList();
      
      // Sort by modification time (newest first)
      files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      
      return files;
    } catch (e) {
      debugPrint('Error getting log files: $e');
      return [];
    }
  }
  
  /// Clear all log files
  Future<void> clearLogs() async {
    try {
      final appDocDir = await path_provider.getApplicationDocumentsDirectory();
      final logDir = Directory('${appDocDir.path}/logs');
      
      if (await logDir.exists()) {
        await logDir.delete(recursive: true);
        await logDir.create();
      }
      
      // Reinitialize the logger
      await init();
    } catch (e) {
      debugPrint('Error clearing logs: $e');
    }
  }
}
