/**
 * Jest setup file
 * Runs before all tests to configure the test environment
 */

// Set environment to test mode
process.env.NODE_ENV = 'test';

// Use in-memory database for all tests
process.env.DATABASE_PATH = ':memory:';

// Disable console.log during tests to reduce noise
// global.console.log = jest.fn();
