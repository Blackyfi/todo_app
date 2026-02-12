const BaseModel = require('./base/BaseModel');
const { getCurrentTimestamp } = require('../utils/helpers');

class Task extends BaseModel {
  constructor() {
    super('tasks');
  }

  /**
   * Upsert task (insert or update based on user_id, device_id, client_id)
   */
  upsertTask(userId, deviceId, taskData) {
    const existing = this.findByCompositeKey(userId, deviceId, taskData.client_id);

    const data = {
      user_id: userId,
      device_id: deviceId,
      client_id: taskData.client_id,
      title: taskData.title,
      description: taskData.description || null,
      due_date: taskData.due_date || null,
      is_completed: taskData.is_completed ? 1 : 0,
      completed_at: taskData.completed_at || null,
      category_id: taskData.category_id || null,
      priority: taskData.priority || 1,
      updated_at: taskData.updated_at || getCurrentTimestamp(),
      deleted: taskData.deleted ? 1 : 0,
      deleted_at: taskData.deleted_at || null,
    };

    if (existing) {
      // Update if client data is newer
      if (data.updated_at >= existing.updated_at) {
        return this.updateByCompositeKey(userId, deviceId, taskData.client_id, data);
      }
      return { updated: false, conflict: true, existing };
    } else {
      // Insert new
      return { updated: true, task: this.create(data) };
    }
  }

  /**
   * Find task by composite key
   */
  findByCompositeKey(userId, deviceId, clientId) {
    return this.findOneWhere('user_id = ? AND device_id = ? AND client_id = ?', [
      userId,
      deviceId,
      clientId,
    ]);
  }

  /**
   * Update by composite key
   */
  updateByCompositeKey(userId, deviceId, clientId, data) {
    // Exclude composite key fields from update data
    const { user_id, device_id, client_id, ...updateData } = data;

    const keys = Object.keys(updateData);
    const values = Object.values(updateData);
    const setClause = keys.map((key) => `${key} = ?`).join(', ');

    const query = `UPDATE ${this.tableName} SET ${setClause} WHERE user_id = ? AND device_id = ? AND client_id = ?`;
    this.exec(query, [...values, userId, deviceId, clientId]);

    return { updated: true, task: this.findByCompositeKey(userId, deviceId, clientId) };
  }

  /**
   * Get all tasks for user
   */
  findByUserId(userId, includeDeleted = false) {
    const whereClause = includeDeleted ? 'user_id = ?' : 'user_id = ? AND deleted = 0';
    return this.findWhere(whereClause, [userId]);
  }

  /**
   * Get tasks updated since timestamp
   */
  findUpdatedSince(userId, sinceTimestamp) {
    return this.findWhere('user_id = ? AND updated_at > ?', [userId, sinceTimestamp]);
  }

  /**
   * Get task statistics
   */
  getTaskStats() {
    const totalTasks = this.count('deleted = 0');
    const completedTasks = this.count('deleted = 0 AND is_completed = 1');
    const completionRate = totalTasks > 0 ? ((completedTasks / totalTasks) * 100).toFixed(2) : 0;

    return {
      total: totalTasks,
      completed: completedTasks,
      completion_rate: parseFloat(completionRate),
    };
  }
}

module.exports = new Task();
