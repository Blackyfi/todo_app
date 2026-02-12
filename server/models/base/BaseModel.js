const { getDatabase } = require('../../database/connection');
const { getCurrentTimestamp } = require('../../utils/helpers');

/**
 * Base model class with common database operations
 */
class BaseModel {
  constructor(tableName) {
    this.tableName = tableName;
    this.db = getDatabase();
  }

  /**
   * Find record by ID
   */
  findById(id) {
    const query = `SELECT * FROM ${this.tableName} WHERE id = ?`;
    return this.db.prepare(query).get(id);
  }

  /**
   * Find all records
   */
  findAll(limit = null, offset = 0) {
    let query = `SELECT * FROM ${this.tableName}`;
    const params = [];

    if (limit) {
      query += ` LIMIT ? OFFSET ?`;
      params.push(limit, offset);
    }

    return this.db.prepare(query).all(...params);
  }

  /**
   * Find records with custom where clause
   */
  findWhere(whereClause, params = []) {
    const query = `SELECT * FROM ${this.tableName} WHERE ${whereClause}`;
    return this.db.prepare(query).all(...params);
  }

  /**
   * Find single record with custom where clause
   */
  findOneWhere(whereClause, params = []) {
    const query = `SELECT * FROM ${this.tableName} WHERE ${whereClause}`;
    return this.db.prepare(query).get(...params);
  }

  /**
   * Create new record
   */
  create(data) {
    const timestamp = getCurrentTimestamp();
    const dataWithTimestamp = {
      created_at: timestamp,
      updated_at: timestamp,
      ...data, // Spread data after defaults to allow overriding timestamps
    };

    const keys = Object.keys(dataWithTimestamp);
    const values = Object.values(dataWithTimestamp);
    const placeholders = keys.map(() => '?').join(', ');

    const query = `INSERT INTO ${this.tableName} (${keys.join(', ')}) VALUES (${placeholders})`;
    const result = this.db.prepare(query).run(...values);

    return this.findById(result.lastInsertRowid);
  }

  /**
   * Update record by ID
   */
  update(id, data) {
    const timestamp = getCurrentTimestamp();
    const dataWithTimestamp = {
      ...data,
      updated_at: timestamp,
    };

    const keys = Object.keys(dataWithTimestamp);
    const values = Object.values(dataWithTimestamp);
    const setClause = keys.map((key) => `${key} = ?`).join(', ');

    const query = `UPDATE ${this.tableName} SET ${setClause} WHERE id = ?`;
    this.db.prepare(query).run(...values, id);

    return this.findById(id);
  }

  /**
   * Delete record by ID (hard delete)
   */
  delete(id) {
    const query = `DELETE FROM ${this.tableName} WHERE id = ?`;
    return this.db.prepare(query).run(id);
  }

  /**
   * Soft delete record by ID
   */
  softDelete(id) {
    const timestamp = getCurrentTimestamp();
    const query = `UPDATE ${this.tableName} SET deleted = 1, deleted_at = ?, updated_at = ? WHERE id = ?`;
    return this.db.prepare(query).run(timestamp, timestamp, id);
  }

  /**
   * Count records
   */
  count(whereClause = null, params = []) {
    let query = `SELECT COUNT(*) as count FROM ${this.tableName}`;

    if (whereClause) {
      query += ` WHERE ${whereClause}`;
    }

    const result = this.db.prepare(query).get(...params);
    return result.count;
  }

  /**
   * Execute custom query
   */
  query(sql, params = []) {
    return this.db.prepare(sql).all(...params);
  }

  /**
   * Execute custom query (single result)
   */
  queryOne(sql, params = []) {
    return this.db.prepare(sql).get(...params);
  }

  /**
   * Execute update query
   */
  exec(sql, params = []) {
    return this.db.prepare(sql).run(...params);
  }
}

module.exports = BaseModel;
