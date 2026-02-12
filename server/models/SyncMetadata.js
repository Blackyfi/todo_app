const BaseModel = require('./base/BaseModel');
const { getCurrentTimestamp } = require('../utils/helpers');

class SyncMetadata extends BaseModel {
  constructor() {
    super('sync_metadata');
  }

  /**
   * Update sync metadata
   */
  updateSyncMetadata(userId, deviceId, entityType, status, error = null) {
    const existing = this.findByCompositeKey(userId, deviceId, entityType);

    const data = {
      user_id: userId,
      device_id: deviceId,
      entity_type: entityType,
      last_sync_at: getCurrentTimestamp(),
      last_sync_status: status,
      sync_count: existing ? existing.sync_count + 1 : 1,
      error_count: status === 'failed' ? (existing ? existing.error_count + 1 : 1) : (existing ? existing.error_count : 0),
      last_error: error,
    };

    if (existing) {
      return this.update(existing.id, data);
    } else {
      return this.create(data);
    }
  }

  /**
   * Find by composite key
   */
  findByCompositeKey(userId, deviceId, entityType) {
    return this.findOneWhere('user_id = ? AND device_id = ? AND entity_type = ?', [
      userId,
      deviceId,
      entityType,
    ]);
  }

  /**
   * Get sync status for user and device
   */
  getSyncStatus(userId, deviceId) {
    return this.findWhere('user_id = ? AND device_id = ?', [userId, deviceId]);
  }

  /**
   * Get sync statistics
   */
  getSyncStats() {
    const twentyFourHoursAgo = getCurrentTimestamp() - 86400;

    const totalQuery = `
      SELECT SUM(sync_count) as total
      FROM ${this.tableName}
      WHERE last_sync_at > ?
    `;
    const totalResult = this.queryOne(totalQuery, [twentyFourHoursAgo]);

    const successQuery = `
      SELECT COUNT(*) as count
      FROM ${this.tableName}
      WHERE last_sync_at > ? AND last_sync_status = 'success'
    `;
    const successResult = this.queryOne(successQuery, [twentyFourHoursAgo]);

    const failedQuery = `
      SELECT COUNT(*) as count
      FROM ${this.tableName}
      WHERE last_sync_at > ? AND last_sync_status = 'failed'
    `;
    const failedResult = this.queryOne(failedQuery, [twentyFourHoursAgo]);

    const total = totalResult.total || 0;
    const successful = successResult.count || 0;
    const failed = failedResult.count || 0;

    return {
      total_today: total,
      successful,
      failed,
      success_rate: total > 0 ? ((successful / (successful + failed)) * 100).toFixed(2) : 100,
    };
  }
}

module.exports = new SyncMetadata();
