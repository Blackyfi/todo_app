import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class DatabaseConfig {
  /// Initialize the appropriate database factory based on platform
  static Future<void> initDatabaseFactory() async {
    // Initialize FFI for desktop/non-mobile platforms
    if (!kIsWeb) {
      // Initialize FFI loader
      sqfliteFfiInit();
      // Set the database factory
      databaseFactory = databaseFactoryFfi;
    }
  }
}