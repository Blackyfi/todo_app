import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class DatabaseConfig {
  /// Initialize the appropriate database factory based on platform
  static Future<void> initDatabaseFactory() async {
    // Initialize FFI for desktop platforms only (not mobile)
    if (!kIsWeb && !Platform.isAndroid && !Platform.isIOS) {
      // Initialize FFI loader
      sqfliteFfiInit();
      // Set the database factory
      databaseFactory = databaseFactoryFfi;
    }
    // On Android and iOS, the regular sqflite plugin will be used
  }
}