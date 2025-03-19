import 'package:sqflite/sqflite.dart' as sql;
import 'package:path/path.dart' as path;

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  static sql.Database? _database;

  Future<sql.Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<sql.Database> _initDatabase() async {
    final dbPath = await sql.getDatabasesPath();
    final pathToDatabase = path.join(dbPath, 'todo_app.db');

    return await sql.openDatabase(
      pathToDatabase,
      version: 1,
      onCreate: _createDb,
    );
  }

  Future<void> _createDb(sql.Database db, int version) async {
    // Create categories table
    await db.execute('''
      CREATE TABLE categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        color INTEGER NOT NULL
      )
    ''');

    // Create tasks table
    await db.execute('''
      CREATE TABLE tasks(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        dueDate INTEGER,
        isCompleted INTEGER NOT NULL DEFAULT 0,
        categoryId INTEGER NOT NULL,
        priority INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (categoryId) REFERENCES categories (id) ON DELETE CASCADE
      )
    ''');

    // Create notification settings table
    await db.execute('''
      CREATE TABLE notificationSettings(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        taskId INTEGER NOT NULL,
        timeOption INTEGER NOT NULL,
        customTime INTEGER,
        FOREIGN KEY (taskId) REFERENCES tasks (id) ON DELETE CASCADE
      )
    ''');

    // Insert default categories
    await db.insert('categories', {'name': 'Work', 'color': 0xFF2196F3});
    await db.insert('categories', {'name': 'Personal', 'color': 0xFF4CAF50});
    await db.insert('categories', {'name': 'Shopping', 'color': 0xFFFF9800});
    await db.insert('categories', {'name': 'Health', 'color': 0xFFF44336});
    await db.insert('categories', {'name': 'Education', 'color': 0xFF9C27B0});
  }
}
