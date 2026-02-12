const path = require('path');

module.exports = {
  // Database file path
  dbPath: process.env.DATABASE_PATH || path.join(__dirname, '../data/todo-sync.db'),

  // SQLite configuration options
  options: {
    verbose: process.env.NODE_ENV !== 'production' ? console.log : null,
  },

  // Pragmas to optimize SQLite performance
  pragmas: [
    'foreign_keys = ON',
    'journal_mode = WAL',
    'synchronous = NORMAL',
    'cache_size = -64000',
    'temp_store = MEMORY',
    'mmap_size = 30000000000',
    'page_size = 4096',
  ],
};
