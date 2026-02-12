const fs = require('fs');
const path = require('path');
const { getDatabase } = require('../connection');
const logger = require('../../utils/logger');

/**
 * Run database migrations
 */
function runMigrations() {
  try {
    logger.info('Starting database migrations...');

    const db = getDatabase();
    const schemaPath = path.join(__dirname, '../schema.sql');
    const schema = fs.readFileSync(schemaPath, 'utf8');

    // Split by semicolons and execute each statement
    const statements = schema
      .split(';')
      .map((stmt) => stmt.trim())
      .filter((stmt) => stmt.length > 0);

    db.transaction(() => {
      statements.forEach((statement) => {
        db.prepare(statement).run();
      });
    })();

    logger.info('Database migrations completed successfully');
    console.log('✓ Database migrations completed successfully');
  } catch (error) {
    logger.error('Migration failed', { error: error.message });
    console.error('✗ Migration failed:', error.message);
    process.exit(1);
  }
}

// Run migrations if executed directly
if (require.main === module) {
  runMigrations();
  process.exit(0);
}

module.exports = { runMigrations };
