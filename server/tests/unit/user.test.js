const User = require('../../models/User');
const { getDatabase, closeDatabase } = require('../../database/connection');
const { runMigrations } = require('../../database/migrations/migration-runner');

describe('User Model', () => {
  beforeAll(() => {
    runMigrations();
  });

  afterAll(() => {
    closeDatabase();
  });

  beforeEach(() => {
    // Clean up users before each test
    const db = getDatabase();
    db.prepare('DELETE FROM users').run();
  });

  test('should create a new user', async () => {
    const user = await User.createUser('testuser', 'Password123!', 'test@example.com');

    expect(user).toBeDefined();
    expect(user.id).toBeDefined();
    expect(user.username).toBe('testuser');
    expect(user.email).toBe('test@example.com');
    expect(user.password_hash).not.toBe('Password123!');
  });

  test('should find user by username', async () => {
    await User.createUser('findme', 'Password123!');
    const user = User.findByUsername('findme');

    expect(user).toBeDefined();
    expect(user.username).toBe('findme');
  });

  test('should verify correct password', async () => {
    const user = await User.createUser('testuser', 'Password123!');
    const isValid = await User.verifyPassword('Password123!', user.password_hash);

    expect(isValid).toBe(true);
  });

  test('should reject incorrect password', async () => {
    const user = await User.createUser('testuser', 'Password123!');
    const isValid = await User.verifyPassword('WrongPassword', user.password_hash);

    expect(isValid).toBe(false);
  });

  test('should throw error for duplicate username', async () => {
    await User.createUser('duplicate', 'Password123!');

    await expect(User.createUser('duplicate', 'Password123!')).rejects.toThrow(
      'Username already exists'
    );
  });

  test('should get user statistics', async () => {
    await User.createUser('user1', 'Password123!');
    await User.createUser('user2', 'Password123!');

    const stats = User.getUserStats();

    expect(stats.total).toBe(2);
  });
});
