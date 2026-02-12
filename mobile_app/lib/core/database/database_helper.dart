import 'package:sqflite/sqflite.dart' as sql;
import 'package:path/path.dart' as path;
import 'package:todo_app/core/logger/logger_service.dart';
import 'package:todo_app/core/database/database_config.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  final LoggerService _logger = LoggerService();

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  static sql.Database? _database;

  Future<sql.Database> get database async {
    if (_database != null) return _database!;
    try {
      await DatabaseConfig.initDatabaseFactory();
      _database = await _initDatabase();
      return _database!;
    } catch (e, stackTrace) {
      await _logger.logError('Failed to initialize database', e, stackTrace);
      rethrow;
    }
  }

  Future<sql.Database> _initDatabase() async {
    try {
      final dbPath = await sql.getDatabasesPath();
      final pathToDatabase = path.join(dbPath, 'todo_app.db');

      await _logger.logInfo('Initializing database at $pathToDatabase');

      return await sql.openDatabase(
        pathToDatabase,
        version: 2,
        onCreate: _createDb,
        onUpgrade: _upgradeDb,
        onOpen: (db) => _logger.logInfo('Database opened successfully'),
      );
    } catch (e, stackTrace) {
      await _logger.logError('Database initialization error', e, stackTrace);
      rethrow;
    }
  }

  Future<void> _createDb(sql.Database db, int version) async {
    try {
      await _logger.logInfo('Creating database tables (version $version)');

      await db.execute('''
        CREATE TABLE categories(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          color INTEGER NOT NULL,
          updatedAt INTEGER
        )
      ''');

      await db.execute('''
        CREATE TABLE tasks(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          description TEXT,
          dueDate INTEGER,
          isCompleted INTEGER NOT NULL DEFAULT 0,
          completedAt INTEGER,
          categoryId INTEGER,
          priority INTEGER NOT NULL DEFAULT 1,
          updatedAt INTEGER,
          FOREIGN KEY (categoryId) REFERENCES categories (id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE notificationSettings(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          taskId INTEGER NOT NULL,
          timeOption INTEGER NOT NULL,
          customTime INTEGER,
          FOREIGN KEY (taskId) REFERENCES tasks (id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE autoDeleteSettings(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          deleteImmediately INTEGER NOT NULL DEFAULT 0,
          deleteAfterDays INTEGER NOT NULL DEFAULT 1
        )
      ''');

      await db.execute('''
        CREATE TABLE widgetConfigs(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          size INTEGER NOT NULL DEFAULT 1,
          showCompleted INTEGER NOT NULL DEFAULT 0,
          showCategories INTEGER NOT NULL DEFAULT 1,
          showPriority INTEGER NOT NULL DEFAULT 1,
          categoryFilter TEXT,
          maxTasks INTEGER NOT NULL DEFAULT 5,
          createdAt INTEGER
        )
      ''');

      await db.execute('''
        CREATE TABLE shoppingLists(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          createdAt INTEGER NOT NULL,
          lastModifiedAt INTEGER
        )
      ''');

      await db.execute('''
        CREATE TABLE groceryItems(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          shoppingListId INTEGER NOT NULL,
          name TEXT NOT NULL,
          quantity REAL NOT NULL DEFAULT 1.0,
          unit TEXT NOT NULL DEFAULT 'pieces',
          isPurchased INTEGER NOT NULL DEFAULT 0,
          createdAt INTEGER NOT NULL,
          purchasedAt INTEGER,
          displayOrder INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY (shoppingListId) REFERENCES shoppingLists (id) ON DELETE CASCADE
        )
      ''');

      await _createSyncTables(db);

      // Insert default categories
      final now = DateTime.now().millisecondsSinceEpoch;
      await db.insert('categories', {
        'name': 'Work', 'color': 0xFF2196F3, 'updatedAt': now,
      });
      await db.insert('categories', {
        'name': 'Personal', 'color': 0xFF4CAF50, 'updatedAt': now,
      });
      await db.insert('categories', {
        'name': 'Shopping', 'color': 0xFFFF9800, 'updatedAt': now,
      });
      await db.insert('categories', {
        'name': 'Health', 'color': 0xFFF44336, 'updatedAt': now,
      });
      await db.insert('categories', {
        'name': 'Education', 'color': 0xFF9C27B0, 'updatedAt': now,
      });

      await db.insert('autoDeleteSettings', {
        'deleteImmediately': 0,
        'deleteAfterDays': 1,
      });

      await _logger.logInfo('Database tables created successfully');
    } catch (e, stackTrace) {
      await _logger.logError('Error creating database tables', e, stackTrace);
      rethrow;
    }
  }

  Future<void> _upgradeDb(
    sql.Database db,
    int oldVersion,
    int newVersion,
  ) async {
    await _logger.logInfo(
      'Upgrading database from v$oldVersion to v$newVersion',
    );

    if (oldVersion < 2) {
      await _migrateToV2(db);
    }
  }

  /// Migration v1 -> v2: Add sync support columns and tables.
  Future<void> _migrateToV2(sql.Database db) async {
    try {
      // Add updatedAt to tasks and categories for change tracking
      await db.execute(
        'ALTER TABLE tasks ADD COLUMN updatedAt INTEGER',
      );
      await db.execute(
        'ALTER TABLE categories ADD COLUMN updatedAt INTEGER',
      );

      // Backfill updatedAt with current timestamp
      final now = DateTime.now().millisecondsSinceEpoch;
      await db.execute('UPDATE tasks SET updatedAt = ?', [now]);
      await db.execute('UPDATE categories SET updatedAt = ?', [now]);

      await _createSyncTables(db);

      await _logger.logInfo('Database migrated to v2 (sync support)');
    } catch (e, stackTrace) {
      await _logger.logError('Error migrating to v2', e, stackTrace);
      rethrow;
    }
  }

  Future<void> _createSyncTables(sql.Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS syncSettings(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        serverUrl TEXT NOT NULL,
        serverPort INTEGER NOT NULL DEFAULT 8443,
        username TEXT,
        useSsl INTEGER NOT NULL DEFAULT 1,
        acceptSelfSignedCert INTEGER NOT NULL DEFAULT 0,
        autoSyncEnabled INTEGER NOT NULL DEFAULT 0,
        syncInterval INTEGER NOT NULL DEFAULT 30,
        lastSyncTimestamp INTEGER,
        deviceId TEXT,
        deviceName TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS syncQueue(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        operation TEXT NOT NULL,
        entityType TEXT NOT NULL,
        entityId INTEGER NOT NULL,
        data TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        retryCount INTEGER NOT NULL DEFAULT 0,
        lastError TEXT
      )
    ''');
  }
}
