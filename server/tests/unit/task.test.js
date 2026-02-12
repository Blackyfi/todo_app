const Task = require('../../models/Task');
const User = require('../../models/User');
const { getDatabase, closeDatabase } = require('../../database/connection');
const { runMigrations } = require('../../database/migrations/migration-runner');

describe('Task Model', () => {
  let testUser;

  beforeAll(() => {
    runMigrations();
  });

  afterAll(() => {
    closeDatabase();
  });

  beforeEach(async () => {
    const db = getDatabase();
    // Clean up tasks first (due to foreign key constraint)
    db.prepare('DELETE FROM tasks').run();
    db.prepare('DELETE FROM users').run();

    // Create a test user for task operations
    testUser = await User.createUser('testuser', 'Password123!');
  });

  test('should upsert new task', () => {
    const taskData = {
      client_id: 1,
      title: 'Test Task',
      description: 'Test Description',
      priority: 1,
      is_completed: 0,
      updated_at: Math.floor(Date.now() / 1000),
      deleted: 0,
    };

    const result = Task.upsertTask(testUser.id, 'device-123', taskData);

    expect(result.updated).toBe(true);
    expect(result.task).toBeDefined();
    expect(result.task.title).toBe('Test Task');
  });

  test('should update existing task', () => {
    const taskData = {
      client_id: 1,
      title: 'Original Title',
      priority: 1,
      is_completed: 0,
      updated_at: 1000,
      deleted: 0,
    };

    Task.upsertTask(testUser.id, 'device-123', taskData);

    const updatedData = {
      ...taskData,
      title: 'Updated Title',
      updated_at: 2000,
    };

    const result = Task.upsertTask(testUser.id, 'device-123', updatedData);

    expect(result.updated).toBe(true);
    expect(result.task.title).toBe('Updated Title');
  });

  test('should handle conflict with older data', () => {
    const taskData = {
      client_id: 1,
      title: 'Newer Version',
      priority: 1,
      is_completed: 0,
      updated_at: 2000,
      deleted: 0,
    };

    Task.upsertTask(testUser.id, 'device-123', taskData);

    const olderData = {
      ...taskData,
      title: 'Older Version',
      updated_at: 1000,
    };

    const result = Task.upsertTask(testUser.id, 'device-123', olderData);

    expect(result.updated).toBe(false);
    expect(result.conflict).toBe(true);
  });

  test('should get task statistics', () => {
    Task.upsertTask(testUser.id, 'device-123', {
      client_id: 1,
      title: 'Task 1',
      priority: 1,
      is_completed: 0,
      updated_at: 1000,
      deleted: 0,
    });

    Task.upsertTask(testUser.id, 'device-123', {
      client_id: 2,
      title: 'Task 2',
      priority: 1,
      is_completed: 1,
      updated_at: 1000,
      deleted: 0,
    });

    const stats = Task.getTaskStats();

    expect(stats.total).toBe(2);
    expect(stats.completed).toBe(1);
    expect(stats.completion_rate).toBe(50);
  });
});
