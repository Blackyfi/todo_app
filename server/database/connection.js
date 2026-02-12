const Database = require('better-sqlite3');
const dbConfig = require('../config/database');
const logger = require('../utils/logger');

let db = null;

/**
 * Initialize database connection
 */
function initializeDatabase() {
  if (db) {
    return db;
  }

  try {
    logger.info(`Initializing database at ${dbConfig.dbPath}`);

    db = new Database(dbConfig.dbPath, dbConfig.options);

    // Apply pragmas for optimization
    dbConfig.pragmas.forEach((pragma) => {
      db.pragma(pragma);
    });

    logger.info('Database initialized successfully');
    return db;
  } catch (error) {
    logger.error('Failed to initialize database', { error: error.message });
    throw error;
  }
}

/**
 * Get database instance
 */
function getDatabase() {
  if (!db) {
    return initializeDatabase();
  }
  return db;
}

/**
 * Close database connection
 */
function closeDatabase() {
  if (db) {
    db.close();
    db = null;
    logger.info('Database connection closed');
  }
}

/**
 * Execute a query with error handling
 */
function executeQuery(query, params = []) {
  try {
    const db = getDatabase();
    return db.prepare(query).all(params);
  } catch (error) {
    logger.error('Query execution failed', { query, error: error.message });
    throw error;
  }
}

/**
 * Execute a single row query
 */
function executeQuerySingle(query, params = []) {
  try {
    const db = getDatabase();
    return db.prepare(query).get(params);
  } catch (error) {
    logger.error('Single query execution failed', { query, error: error.message });
    throw error;
  }
}

/**
 * Execute an insert/update/delete query
 */
function executeUpdate(query, params = []) {
  try {
    const db = getDatabase();
    return db.prepare(query).run(params);
  } catch (error) {
    logger.error('Update execution failed', { query, error: error.message });
    throw error;
  }
}

/**
 * Execute within a transaction
 */
function transaction(callback) {
  const db = getDatabase();
  const txn = db.transaction(callback);
  return txn();
}

module.exports = {
  initializeDatabase,
  getDatabase,
  closeDatabase,
  executeQuery,
  executeQuerySingle,
  executeUpdate,
  transaction,
};
