const BaseModel = require('./base/BaseModel');
const { getCurrentTimestamp } = require('../utils/helpers');

class Category extends BaseModel {
  constructor() {
    super('categories');
  }

  upsertCategory(userId, deviceId, categoryData) {
    const existing = this.findByCompositeKey(userId, deviceId, categoryData.client_id);

    const data = {
      user_id: userId,
      device_id: deviceId,
      client_id: categoryData.client_id,
      name: categoryData.name,
      color: categoryData.color,
      updated_at: categoryData.updated_at || getCurrentTimestamp(),
      deleted: categoryData.deleted ? 1 : 0,
      deleted_at: categoryData.deleted_at || null,
    };

    if (existing) {
      if (data.updated_at >= existing.updated_at) {
        return this.updateByCompositeKey(userId, deviceId, categoryData.client_id, data);
      }
      return { updated: false, conflict: true, existing };
    } else {
      return { updated: true, category: this.create(data) };
    }
  }

  findByCompositeKey(userId, deviceId, clientId) {
    return this.findOneWhere('user_id = ? AND device_id = ? AND client_id = ?', [
      userId,
      deviceId,
      clientId,
    ]);
  }

  updateByCompositeKey(userId, deviceId, clientId, data) {
    const keys = Object.keys(data);
    const values = Object.values(data);
    const setClause = keys.map((key) => `${key} = ?`).join(', ');

    const query = `UPDATE ${this.tableName} SET ${setClause} WHERE user_id = ? AND device_id = ? AND client_id = ?`;
    this.exec(query, [...values, userId, deviceId, clientId]);

    return { updated: true, category: this.findByCompositeKey(userId, deviceId, clientId) };
  }

  findByUserId(userId, includeDeleted = false) {
    const whereClause = includeDeleted ? 'user_id = ?' : 'user_id = ? AND deleted = 0';
    return this.findWhere(whereClause, [userId]);
  }

  findUpdatedSince(userId, sinceTimestamp) {
    return this.findWhere('user_id = ? AND updated_at > ?', [userId, sinceTimestamp]);
  }
}

module.exports = new Category();
