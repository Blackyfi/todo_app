# Todo Sync Server - Complete Implementation Specification

## Executive Summary

This document specifies the complete implementation of a production-ready REST API server for synchronizing todo list data across multiple devices. The server is designed to be lightweight, secure, and efficient, running on Ubuntu Server 24.04 with minimal resource consumption (2GB RAM, 2 CPU cores).

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Technology Stack](#technology-stack)
3. [Project Structure](#project-structure)
4. [Database Schema](#database-schema)
5. [API Endpoints](#api-endpoints)
6. [Security Implementation](#security-implementation)
7. [Sync Logic](#sync-logic)
8. [Web UI Dashboard](#web-ui-dashboard)
9. [Deployment & Operations](#deployment--operations)
10. [Testing Strategy](#testing-strategy)

---

## Architecture Overview

### System Design

```
┌─────────────────────────────────────────────────────────────┐
│                     Client Devices                           │
│  (Flutter Apps on Android/iOS/Desktop/Web)                   │
└───────────────────┬─────────────────────────────────────────┘
                    │ HTTPS (Port 8443)
                    │ JWT Authentication
                    │
┌───────────────────▼─────────────────────────────────────────┐
│              HTTPS Reverse Proxy (Optional)                  │
│              - Rate Limiting                                 │
│              - DDoS Protection                               │
└───────────────────┬─────────────────────────────────────────┘
                    │
┌───────────────────▼─────────────────────────────────────────┐
│              Node.js Express Server                          │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  Middleware Layer                                    │    │
│  │  - CORS, Helmet, Compression                        │    │
│  │  - JWT Authentication                                │    │
│  │  - Request Validation                                │    │
│  │  - Rate Limiting                                     │    │
│  │  - Error Handling                                    │    │
│  └─────────────────────────────────────────────────────┘    │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  Route Layer                                         │    │
│  │  /api/auth | /api/sync | /api/devices | /api/admin  │    │
│  └─────────────────────────────────────────────────────┘    │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  Controller Layer                                    │    │
│  │  Business Logic & Data Validation                   │    │
│  └─────────────────────────────────────────────────────┘    │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  Model Layer                                         │    │
│  │  Data Access & Database Operations                  │    │
│  └─────────────────────────────────────────────────────┘    │
└───────────────────┬─────────────────────────────────────────┘
                    │
┌───────────────────▼─────────────────────────────────────────┐
│              SQLite Database                                 │
│  - Embedded, file-based                                      │
│  - ACID compliant                                            │
│  - WAL mode for performance                                 │
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│              Web UI Dashboard (Separate Port 3000)           │
│  - Lightweight static HTML/CSS/JS                            │
│  - Real-time KPIs via WebSocket                             │
│  - Server statistics & device monitoring                     │
└──────────────────────────────────────────────────────────────┘
```

### Key Design Principles

1. **Stateless Architecture**: Each request contains all necessary authentication information (JWT)
2. **RESTful Design**: Predictable URL structure, proper HTTP methods and status codes
3. **Conflict Resolution**: Last-write-wins based on `updated_at` timestamps
4. **Soft Deletes**: Data is never physically deleted, only marked as deleted
5. **Transaction Safety**: Multi-step operations wrapped in database transactions
6. **Horizontal Scalability**: While starting single-server, architecture supports future load balancing
7. **Defense in Depth**: Multiple security layers (HTTPS, JWT, validation, rate limiting, sanitization)

---

## Technology Stack

### Core Technologies

| Component | Technology | Version | Rationale |
|-----------|-----------|---------|-----------|
| Runtime | Node.js | 20.x LTS | Long-term support, excellent async performance |
| Framework | Express.js | 4.x | Minimal, flexible, proven for REST APIs |
| Database | SQLite3 | Latest | Embedded, zero-config, single file, ACID compliant |
| Authentication | JWT | - | Stateless, scalable, industry standard |
| Password Hashing | bcrypt | Latest | Adaptive, slow, resistant to brute force |
| Logging | Winston | 3.x | Flexible, rotating logs, multiple transports |
| Process Manager | PM2 | Latest | Auto-restart, monitoring, cluster mode support |

### Dependencies

**Production Dependencies:**
```json
{
  "express": "^4.18.2",
  "sqlite3": "^5.1.6",
  "better-sqlite3": "^9.2.2",
  "bcrypt": "^5.1.1",
  "jsonwebtoken": "^9.0.2",
  "express-validator": "^7.0.1",
  "express-rate-limit": "^7.1.5",
  "helmet": "^7.1.0",
  "cors": "^2.8.5",
  "compression": "^1.7.4",
  "morgan": "^1.10.0",
  "winston": "^3.11.0",
  "winston-daily-rotate-file": "^4.7.1",
  "dotenv": "^16.3.1",
  "uuid": "^9.0.1",
  "express-async-handler": "^1.2.0",
  "socket.io": "^4.6.0",
  "ws": "^8.16.0"
}
```

**Development Dependencies:**
```json
{
  "nodemon": "^3.0.2",
  "jest": "^29.7.0",
  "supertest": "^6.3.3",
  "eslint": "^8.56.0",
  "prettier": "^3.1.1"
}
```

### System Requirements

- **OS**: Ubuntu Server 24.04 LTS
- **CPU**: 2 cores (minimum)
- **RAM**: 2GB (minimum), 4GB (recommended)
- **Storage**: 32GB (10GB free minimum for data and logs)
- **Network**: Static IP or DDNS, port 8443 accessible via VPN/port forwarding

---

## Project Structure

### Complete Directory Layout

```
/opt/todo-sync-server/
│
├── server.js                      # Main application entry point
├── package.json                   # Project dependencies and scripts
├── package-lock.json             # Dependency lock file
├── .env                          # Environment variables (NOT in git)
├── .env.example                  # Example environment file (in git)
├── .gitignore                    # Git ignore rules
├── .eslintrc.json               # ESLint configuration
├── .prettierrc                  # Prettier configuration
├── README.md                     # Complete setup documentation
├── DEPLOYMENT.md                 # Deployment guide
├── API.md                        # API documentation
├── ecosystem.config.js           # PM2 process configuration
│
├── config/
│   ├── database.js              # Database configuration
│   ├── jwt.js                   # JWT configuration
│   ├── ssl.js                   # SSL/TLS configuration
│   └── app.js                   # Application configuration
│
├── database/
│   ├── connection.js            # SQLite connection pool
│   ├── schema.sql               # Database schema DDL
│   ├── migrations/              # Database migration scripts
│   │   ├── 001_initial_schema.js
│   │   ├── 002_add_indexes.js
│   │   └── migration-runner.js
│   └── seeders/                 # Development seed data
│       └── dev-seed.js
│
├── models/
│   ├── User.js                  # User model and queries
│   ├── Device.js                # Device model
│   ├── Task.js                  # Task model
│   ├── Category.js              # Category model
│   ├── NotificationSetting.js   # Notification settings model
│   ├── ShoppingList.js          # Shopping list model
│   ├── ShoppingItem.js          # Shopping item model
│   ├── AutoDeleteSetting.js     # Auto-delete settings model
│   ├── SyncMetadata.js          # Sync metadata model
│   ├── ApiToken.js              # API token model
│   └── base/
│       └── BaseModel.js         # Base model with common methods
│
├── controllers/
│   ├── authController.js        # Authentication logic
│   ├── syncController.js        # Sync upload/download logic
│   ├── deviceController.js      # Device management logic
│   ├── adminController.js       # Admin dashboard logic
│   └── healthController.js      # Health check logic
│
├── routes/
│   ├── index.js                 # Main router combining all routes
│   ├── auth.js                  # Authentication routes
│   ├── sync.js                  # Sync routes
│   ├── devices.js               # Device routes
│   ├── admin.js                 # Admin routes
│   └── health.js                # Health check route
│
├── middleware/
│   ├── auth.js                  # JWT authentication middleware
│   ├── validate.js              # Request validation middleware
│   ├── errorHandler.js          # Global error handler
│   ├── asyncHandler.js          # Async error wrapper
│   ├── rateLimiter.js           # Rate limiting middleware
│   ├── sanitize.js              # Input sanitization
│   ├── logging.js               # Request logging
│   └── cors.js                  # CORS configuration
│
├── utils/
│   ├── logger.js                # Winston logger configuration
│   ├── encryption.js            # Encryption utilities
│   ├── validation.js            # Validation helper functions
│   ├── errors.js                # Custom error classes
│   ├── response.js              # Standardized response helper
│   └── helpers.js               # General utility functions
│
├── ssl/
│   ├── cert.pem                 # SSL certificate (self-signed initially)
│   ├── key.pem                  # SSL private key
│   ├── generate-cert.sh         # Script to generate self-signed cert
│   └── README.md                # SSL setup instructions
│
├── data/
│   └── todo-sync.db             # SQLite database (auto-created)
│
├── logs/
│   ├── error.log                # Error logs
│   ├── combined.log             # All logs
│   ├── access.log               # HTTP access logs
│   └── .gitkeep                 # Keep directory in git
│
├── public/                       # Web UI static files
│   ├── index.html               # Dashboard main page
│   ├── css/
│   │   └── style.css            # Dashboard styles
│   ├── js/
│   │   ├── dashboard.js         # Dashboard logic
│   │   └── charts.js            # Chart rendering (Chart.js)
│   └── assets/
│       └── logo.png             # Logo/icons
│
├── scripts/
│   ├── backup.sh                # Database backup script
│   ├── restore.sh               # Database restore script
│   ├── setup.sh                 # Initial setup script
│   ├── generate-jwt-secret.sh   # Generate secure JWT secret
│   └── migrate.sh               # Run database migrations
│
├── tests/
│   ├── unit/                    # Unit tests
│   │   ├── models/
│   │   ├── controllers/
│   │   └── utils/
│   ├── integration/             # Integration tests
│   │   ├── auth.test.js
│   │   ├── sync.test.js
│   │   └── devices.test.js
│   └── setup.js                 # Test environment setup
│
└── docs/
    ├── API.md                   # Complete API documentation
    ├── ARCHITECTURE.md          # Architecture decisions
    ├── SECURITY.md              # Security considerations
    └── TROUBLESHOOTING.md       # Common issues and solutions
```

---

## Database Schema

### Schema Design Philosophy

1. **User Isolation**: All data scoped to `user_id` for multi-tenant support
2. **Device Tracking**: Track which device created/modified each entity
3. **Soft Deletes**: Never physically delete data, use `deleted` flag
4. **Timestamps**: Track creation and modification times for conflict resolution
5. **Indexes**: Optimize for common query patterns (user_id, device_id, updated_at)
6. **Foreign Keys**: Enforce referential integrity with CASCADE deletes

### Complete SQL Schema

```sql
-- ============================================
-- USERS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT NOT NULL UNIQUE,
    email TEXT UNIQUE,
    password_hash TEXT NOT NULL,
    created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
    updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
    last_login_at INTEGER,
    is_active INTEGER NOT NULL DEFAULT 1,
    is_admin INTEGER NOT NULL DEFAULT 0
);

CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_created_at ON users(created_at);

-- ============================================
-- DEVICES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS devices (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    device_id TEXT NOT NULL,
    device_name TEXT NOT NULL,
    device_type TEXT, -- android, ios, web, windows, macos, linux
    app_version TEXT,
    os_version TEXT,
    created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
    last_seen_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
    is_active INTEGER NOT NULL DEFAULT 1,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE(user_id, device_id)
);

CREATE INDEX idx_devices_user_id ON devices(user_id);
CREATE INDEX idx_devices_device_id ON devices(device_id);
CREATE INDEX idx_devices_last_seen ON devices(last_seen_at);

-- ============================================
-- API TOKENS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS api_tokens (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    device_id TEXT NOT NULL,
    token_hash TEXT NOT NULL,
    expires_at INTEGER NOT NULL,
    created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
    revoked_at INTEGER,
    is_active INTEGER NOT NULL DEFAULT 1,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_tokens_user_id ON api_tokens(user_id);
CREATE INDEX idx_tokens_hash ON api_tokens(token_hash);
CREATE INDEX idx_tokens_expires ON api_tokens(expires_at);

-- ============================================
-- CATEGORIES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS categories (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    device_id TEXT NOT NULL,
    client_id INTEGER NOT NULL, -- Original ID from client device
    name TEXT NOT NULL,
    color INTEGER NOT NULL,
    created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
    updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
    deleted INTEGER NOT NULL DEFAULT 0,
    deleted_at INTEGER,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE(user_id, device_id, client_id)
);

CREATE INDEX idx_categories_user_id ON categories(user_id);
CREATE INDEX idx_categories_device_id ON categories(device_id);
CREATE INDEX idx_categories_updated_at ON categories(updated_at);
CREATE INDEX idx_categories_deleted ON categories(deleted);

-- ============================================
-- TASKS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS tasks (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    device_id TEXT NOT NULL,
    client_id INTEGER NOT NULL, -- Original ID from client device
    title TEXT NOT NULL,
    description TEXT,
    due_date INTEGER,
    is_completed INTEGER NOT NULL DEFAULT 0,
    completed_at INTEGER,
    category_id INTEGER,
    priority INTEGER NOT NULL DEFAULT 1, -- 0=low, 1=medium, 2=high
    created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
    updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
    deleted INTEGER NOT NULL DEFAULT 0,
    deleted_at INTEGER,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE(user_id, device_id, client_id)
);

CREATE INDEX idx_tasks_user_id ON tasks(user_id);
CREATE INDEX idx_tasks_device_id ON tasks(device_id);
CREATE INDEX idx_tasks_category_id ON tasks(category_id);
CREATE INDEX idx_tasks_updated_at ON tasks(updated_at);
CREATE INDEX idx_tasks_deleted ON tasks(deleted);
CREATE INDEX idx_tasks_completed ON tasks(is_completed);
CREATE INDEX idx_tasks_due_date ON tasks(due_date);

-- ============================================
-- NOTIFICATION SETTINGS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS notification_settings (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    device_id TEXT NOT NULL,
    client_id INTEGER NOT NULL,
    task_client_id INTEGER NOT NULL, -- References task's client_id
    notification_time INTEGER NOT NULL,
    notification_type TEXT, -- 'at_time', 'before_15min', etc.
    is_enabled INTEGER NOT NULL DEFAULT 1,
    created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
    updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
    deleted INTEGER NOT NULL DEFAULT 0,
    deleted_at INTEGER,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE(user_id, device_id, client_id)
);

CREATE INDEX idx_notifications_user_id ON notification_settings(user_id);
CREATE INDEX idx_notifications_task_id ON notification_settings(task_client_id);
CREATE INDEX idx_notifications_updated_at ON notification_settings(updated_at);

-- ============================================
-- SHOPPING LISTS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS shopping_lists (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    device_id TEXT NOT NULL,
    client_id INTEGER NOT NULL,
    name TEXT NOT NULL,
    created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
    updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
    deleted INTEGER NOT NULL DEFAULT 0,
    deleted_at INTEGER,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE(user_id, device_id, client_id)
);

CREATE INDEX idx_shopping_lists_user_id ON shopping_lists(user_id);
CREATE INDEX idx_shopping_lists_updated_at ON shopping_lists(updated_at);

-- ============================================
-- SHOPPING ITEMS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS shopping_items (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    device_id TEXT NOT NULL,
    client_id INTEGER NOT NULL,
    list_client_id INTEGER NOT NULL, -- References shopping_list's client_id
    name TEXT NOT NULL,
    quantity TEXT,
    is_checked INTEGER NOT NULL DEFAULT 0,
    created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
    updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
    deleted INTEGER NOT NULL DEFAULT 0,
    deleted_at INTEGER,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE(user_id, device_id, client_id)
);

CREATE INDEX idx_shopping_items_user_id ON shopping_items(user_id);
CREATE INDEX idx_shopping_items_list_id ON shopping_items(list_client_id);
CREATE INDEX idx_shopping_items_updated_at ON shopping_items(updated_at);

-- ============================================
-- AUTO DELETE SETTINGS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS auto_delete_settings (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    device_id TEXT NOT NULL,
    is_enabled INTEGER NOT NULL DEFAULT 0,
    delete_after_days INTEGER NOT NULL DEFAULT 0,
    created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
    updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE(user_id, device_id)
);

CREATE INDEX idx_auto_delete_user_id ON auto_delete_settings(user_id);

-- ============================================
-- SYNC METADATA TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS sync_metadata (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    device_id TEXT NOT NULL,
    entity_type TEXT NOT NULL, -- 'task', 'category', 'shopping_list', etc.
    last_sync_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
    last_sync_status TEXT, -- 'success', 'partial', 'failed'
    sync_count INTEGER NOT NULL DEFAULT 0,
    error_count INTEGER NOT NULL DEFAULT 0,
    last_error TEXT,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE(user_id, device_id, entity_type)
);

CREATE INDEX idx_sync_metadata_user_id ON sync_metadata(user_id);
CREATE INDEX idx_sync_metadata_device_id ON sync_metadata(device_id);
CREATE INDEX idx_sync_metadata_last_sync ON sync_metadata(last_sync_at);

-- ============================================
-- SERVER STATISTICS TABLE (for dashboard)
-- ============================================
CREATE TABLE IF NOT EXISTS server_stats (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    metric_name TEXT NOT NULL,
    metric_value TEXT NOT NULL,
    recorded_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
);

CREATE INDEX idx_server_stats_name ON server_stats(metric_name);
CREATE INDEX idx_server_stats_recorded ON server_stats(recorded_at);
```

### Database Configuration

**SQLite Pragmas** (applied on connection):
```sql
PRAGMA foreign_keys = ON;           -- Enforce foreign key constraints
PRAGMA journal_mode = WAL;          -- Write-Ahead Logging for better concurrency
PRAGMA synchronous = NORMAL;        -- Balance between safety and performance
PRAGMA cache_size = -64000;         -- 64MB cache
PRAGMA temp_store = MEMORY;         -- Temporary tables in memory
PRAGMA mmap_size = 30000000000;     -- Memory-mapped I/O
PRAGMA page_size = 4096;            -- Optimal page size
```

---

## API Endpoints

### Authentication Endpoints

#### POST /api/auth/register
Register a new user account.

**Request:**
```json
{
  "username": "john_doe",
  "email": "john@example.com",
  "password": "SecurePass123!"
}
```

**Response (201):**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": 1,
      "username": "john_doe",
      "email": "john@example.com",
      "created_at": 1704067200
    }
  },
  "message": "User registered successfully"
}
```

**Validation:**
- Username: 3-30 alphanumeric characters, underscores allowed
- Email: Valid email format
- Password: Minimum 8 characters, at least 1 uppercase, 1 lowercase, 1 number

---

#### POST /api/auth/login
Authenticate user and receive JWT token.

**Request:**
```json
{
  "username": "john_doe",
  "password": "SecurePass123!",
  "device_id": "device-uuid-12345",
  "device_name": "John's iPhone",
  "device_type": "ios",
  "app_version": "1.0.0",
  "os_version": "iOS 17.2"
}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "expires_at": 1704672000,
    "user": {
      "id": 1,
      "username": "john_doe",
      "email": "john@example.com"
    },
    "device": {
      "id": 1,
      "device_id": "device-uuid-12345",
      "device_name": "John's iPhone"
    }
  },
  "message": "Login successful"
}
```

---

#### POST /api/auth/refresh
Refresh an expired or expiring JWT token.

**Request:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "expires_at": 1705276800
  }
}
```

---

#### POST /api/auth/logout
Invalidate current JWT token.

**Headers:**
```
Authorization: Bearer <token>
```

**Response (200):**
```json
{
  "success": true,
  "message": "Logged out successfully"
}
```

---

### Device Endpoints

#### GET /api/devices
List all devices for authenticated user.

**Headers:**
```
Authorization: Bearer <token>
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "devices": [
      {
        "id": 1,
        "device_id": "device-uuid-12345",
        "device_name": "John's iPhone",
        "device_type": "ios",
        "app_version": "1.0.0",
        "os_version": "iOS 17.2",
        "created_at": 1704067200,
        "last_seen_at": 1704672000,
        "is_active": 1
      },
      {
        "id": 2,
        "device_id": "device-uuid-67890",
        "device_name": "John's Laptop",
        "device_type": "windows",
        "app_version": "1.0.0",
        "os_version": "Windows 11",
        "created_at": 1704153600,
        "last_seen_at": 1704668400,
        "is_active": 1
      }
    ],
    "count": 2
  }
}
```

---

#### DELETE /api/devices/:deviceId
Unregister a device (soft delete).

**Headers:**
```
Authorization: Bearer <token>
```

**Response (200):**
```json
{
  "success": true,
  "message": "Device unregistered successfully"
}
```

---

### Sync Endpoints

#### POST /api/sync/upload
Upload changes from device to server.

**Headers:**
```
Authorization: Bearer <token>
Content-Type: application/json
```

**Request:**
```json
{
  "device_id": "device-uuid-12345",
  "sync_timestamp": 1704672000,
  "data": {
    "categories": [
      {
        "client_id": 1,
        "name": "Work",
        "color": 4280391411,
        "updated_at": 1704672000,
        "deleted": 0
      }
    ],
    "tasks": [
      {
        "client_id": 1,
        "title": "Complete project report",
        "description": "Quarterly report for Q4",
        "due_date": 1704758400,
        "is_completed": 0,
        "category_id": 1,
        "priority": 2,
        "updated_at": 1704672000,
        "deleted": 0
      },
      {
        "client_id": 2,
        "title": "Team meeting",
        "description": "Weekly sync",
        "due_date": 1704844800,
        "is_completed": 1,
        "completed_at": 1704672000,
        "category_id": 1,
        "priority": 1,
        "updated_at": 1704672000,
        "deleted": 0
      }
    ],
    "notification_settings": [
      {
        "client_id": 1,
        "task_client_id": 1,
        "notification_time": 1704754800,
        "notification_type": "before_1hour",
        "is_enabled": 1,
        "updated_at": 1704672000,
        "deleted": 0
      }
    ],
    "shopping_lists": [],
    "shopping_items": [],
    "auto_delete_settings": {
      "is_enabled": 1,
      "delete_after_days": 30,
      "updated_at": 1704672000
    }
  }
}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "uploaded": {
      "categories": 1,
      "tasks": 2,
      "notification_settings": 1,
      "shopping_lists": 0,
      "shopping_items": 0
    },
    "conflicts_resolved": {
      "tasks": 0
    },
    "sync_timestamp": 1704672100
  },
  "message": "Data uploaded successfully"
}
```

---

#### GET /api/sync/download
Download all user data or changes since timestamp.

**Headers:**
```
Authorization: Bearer <token>
```

**Query Parameters:**
- `since` (optional): Unix timestamp, returns only changes after this time
- `device_id`: Device identifier

**Response (200):**
```json
{
  "success": true,
  "data": {
    "categories": [
      {
        "id": 1,
        "client_id": 1,
        "device_id": "device-uuid-12345",
        "name": "Work",
        "color": 4280391411,
        "created_at": 1704067200,
        "updated_at": 1704672000,
        "deleted": 0
      }
    ],
    "tasks": [
      {
        "id": 1,
        "client_id": 1,
        "device_id": "device-uuid-12345",
        "title": "Complete project report",
        "description": "Quarterly report for Q4",
        "due_date": 1704758400,
        "is_completed": 0,
        "category_id": 1,
        "priority": 2,
        "created_at": 1704067200,
        "updated_at": 1704672000,
        "deleted": 0
      }
    ],
    "notification_settings": [],
    "shopping_lists": [],
    "shopping_items": [],
    "auto_delete_settings": {
      "is_enabled": 1,
      "delete_after_days": 30,
      "updated_at": 1704672000
    },
    "sync_timestamp": 1704672100
  }
}
```

---

#### GET /api/sync/status
Get last sync status and server timestamp.

**Headers:**
```
Authorization: Bearer <token>
```

**Query Parameters:**
- `device_id`: Device identifier

**Response (200):**
```json
{
  "success": true,
  "data": {
    "last_sync": {
      "categories": {
        "last_sync_at": 1704672000,
        "status": "success",
        "sync_count": 15
      },
      "tasks": {
        "last_sync_at": 1704672000,
        "status": "success",
        "sync_count": 42
      }
    },
    "server_timestamp": 1704672100,
    "pending_changes": false
  }
}
```

---

#### POST /api/sync/resolve-conflict
Manually resolve a sync conflict (advanced).

**Headers:**
```
Authorization: Bearer <token>
Content-Type: application/json
```

**Request:**
```json
{
  "entity_type": "task",
  "client_id": 1,
  "device_id": "device-uuid-12345",
  "resolution": "server" | "client",
  "client_data": { /* complete entity object */ }
}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "resolved_entity": { /* final entity after resolution */ }
  },
  "message": "Conflict resolved successfully"
}
```

---

### Health & Admin Endpoints

#### GET /api/health
Server health check (no authentication required).

**Response (200):**
```json
{
  "success": true,
  "data": {
    "status": "healthy",
    "timestamp": 1704672100,
    "uptime": 86400,
    "version": "1.0.0",
    "database": "connected"
  }
}
```

---

#### GET /api/admin/stats
Admin dashboard statistics (requires admin authentication).

**Headers:**
```
Authorization: Bearer <admin-token>
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "users": {
      "total": 42,
      "active_today": 15,
      "new_this_week": 3
    },
    "devices": {
      "total": 87,
      "active_today": 28,
      "by_type": {
        "android": 35,
        "ios": 28,
        "windows": 15,
        "web": 9
      }
    },
    "syncs": {
      "total_today": 156,
      "successful": 154,
      "failed": 2,
      "avg_duration_ms": 45
    },
    "database": {
      "size_mb": 12.5,
      "tasks_count": 1247,
      "categories_count": 89
    },
    "server": {
      "uptime_seconds": 432000,
      "memory_usage_mb": 145,
      "cpu_usage_percent": 8.5
    }
  }
}
```

---

## Security Implementation

### Password Security

**Hashing Strategy:**
```javascript
const bcrypt = require('bcrypt');
const SALT_ROUNDS = 12;

// Hash password on registration
async function hashPassword(password) {
  return await bcrypt.hash(password, SALT_ROUNDS);
}

// Verify password on login
async function verifyPassword(password, hash) {
  return await bcrypt.compare(password, hash);
}
```

**Password Requirements:**
- Minimum 8 characters
- At least 1 uppercase letter
- At least 1 lowercase letter
- At least 1 number
- At least 1 special character (recommended, not enforced)

---

### JWT Authentication

**Token Structure:**
```javascript
const jwt = require('jsonwebtoken');

// Generate JWT token
function generateToken(user, device) {
  const payload = {
    user_id: user.id,
    username: user.username,
    device_id: device.device_id,
    is_admin: user.is_admin,
    iat: Math.floor(Date.now() / 1000)
  };

  return jwt.sign(payload, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN || '7d',
    algorithm: 'HS256'
  });
}

// Verify JWT token
function verifyToken(token) {
  try {
    return jwt.verify(token, process.env.JWT_SECRET);
  } catch (error) {
    throw new AuthenticationError('Invalid or expired token');
  }
}
```

**Token Lifecycle:**
1. Token generated on login with 7-day expiration
2. Token stored in database (hashed) for revocation support
3. Client includes token in `Authorization: Bearer <token>` header
4. Server validates token on each request
5. Token can be refreshed before expiration
6. Token revoked on logout or security events

---

### Rate Limiting

**Configuration:**
```javascript
const rateLimit = require('express-rate-limit');

// Auth endpoints (stricter)
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 5, // 5 requests per window
  message: 'Too many authentication attempts, please try again later',
  standardHeaders: true,
  legacyHeaders: false
});

// API endpoints (moderate)
const apiLimiter = rateLimit({
  windowMs: 1 * 60 * 1000, // 1 minute
  max: 30, // 30 requests per window
  message: 'Too many requests, please slow down',
  standardHeaders: true,
  legacyHeaders: false
});

// Sync endpoints (generous but tracked)
const syncLimiter = rateLimit({
  windowMs: 1 * 60 * 1000, // 1 minute
  max: 10, // 10 sync requests per minute
  message: 'Sync rate limit exceeded',
  standardHeaders: true,
  legacyHeaders: false
});
```

---

### Input Validation & Sanitization

**Validation Middleware:**
```javascript
const { body, param, query, validationResult } = require('express-validator');

// Example: Task validation
const validateTask = [
  body('title')
    .trim()
    .isLength({ min: 1, max: 255 })
    .withMessage('Title must be 1-255 characters'),
  body('description')
    .optional()
    .trim()
    .isLength({ max: 5000 })
    .withMessage('Description must be under 5000 characters'),
  body('due_date')
    .optional()
    .isInt({ min: 0 })
    .withMessage('Due date must be a valid Unix timestamp'),
  body('priority')
    .optional()
    .isIn([0, 1, 2])
    .withMessage('Priority must be 0 (low), 1 (medium), or 2 (high)'),
  body('is_completed')
    .optional()
    .isBoolean()
    .withMessage('is_completed must be boolean')
];

// Validation result handler
function handleValidationErrors(req, res, next) {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({
      success: false,
      errors: errors.array()
    });
  }
  next();
}
```

---

### HTTPS/SSL Configuration

**Self-Signed Certificate Generation:**
```bash
#!/bin/bash
# ssl/generate-cert.sh

openssl req -x509 -newkey rsa:4096 -nodes \
  -keyout key.pem \
  -out cert.pem \
  -days 365 \
  -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost"

chmod 600 key.pem
chmod 644 cert.pem

echo "Self-signed SSL certificate generated successfully"
echo "Certificate: cert.pem"
echo "Private key: key.pem"
echo ""
echo "For production, replace with Let's Encrypt certificate:"
echo "  certbot certonly --standalone -d yourdomain.com"
```

**HTTPS Server Configuration:**
```javascript
const https = require('https');
const fs = require('fs');
const express = require('express');

const app = express();

// SSL options
const httpsOptions = {
  key: fs.readFileSync(process.env.SSL_KEY_PATH || './ssl/key.pem'),
  cert: fs.readFileSync(process.env.SSL_CERT_PATH || './ssl/cert.pem'),
  // Security options
  minVersion: 'TLSv1.2',
  ciphers: [
    'ECDHE-ECDSA-AES128-GCM-SHA256',
    'ECDHE-RSA-AES128-GCM-SHA256',
    'ECDHE-ECDSA-AES256-GCM-SHA384',
    'ECDHE-RSA-AES256-GCM-SHA384'
  ].join(':')
};

// Create HTTPS server
const server = https.createServer(httpsOptions, app);

server.listen(process.env.PORT || 8443, () => {
  console.log(`HTTPS server running on port ${process.env.PORT || 8443}`);
});
```

---

### CORS Configuration

```javascript
const cors = require('cors');

const corsOptions = {
  origin: function (origin, callback) {
    const allowedOrigins = process.env.ALLOWED_ORIGINS
      ? process.env.ALLOWED_ORIGINS.split(',')
      : ['http://localhost:3000'];

    // Allow requests with no origin (mobile apps, Postman, etc.)
    if (!origin) return callback(null, true);

    if (allowedOrigins.indexOf(origin) !== -1 || allowedOrigins.includes('*')) {
      callback(null, true);
    } else {
      callback(new Error('Not allowed by CORS'));
    }
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  maxAge: 86400 // 24 hours
};

app.use(cors(corsOptions));
```

---

### Security Headers (Helmet)

```javascript
const helmet = require('helmet');

app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      scriptSrc: ["'self'"],
      imgSrc: ["'self'", "data:", "https:"],
    },
  },
  hsts: {
    maxAge: 31536000,
    includeSubDomains: true,
    preload: true
  },
  frameguard: {
    action: 'deny'
  },
  noSniff: true,
  xssFilter: true
}));
```

---

## Sync Logic

### Sync Algorithm Overview

The synchronization system uses a **last-write-wins (LWW)** conflict resolution strategy based on `updated_at` timestamps. This approach is simple, predictable, and sufficient for most use cases where conflicts are rare.

### Sync Flow Diagram

```
┌─────────────┐                                    ┌─────────────┐
│   Client    │                                    │   Server    │
│   Device    │                                    │  Database   │
└──────┬──────┘                                    └──────┬──────┘
       │                                                  │
       │  1. POST /api/sync/upload                       │
       │     {tasks: [...], categories: [...]}           │
       ├────────────────────────────────────────────────>│
       │                                                  │
       │                     2. For each entity:          │
       │                        - Check if exists         │
       │                        - Compare updated_at      │
       │                        - Apply LWW resolution    │
       │                        - Upsert to database      │
       │                                                  │
       │  3. Response: {uploaded: {...}, conflicts: {...}}│
       │<────────────────────────────────────────────────┤
       │                                                  │
       │  4. GET /api/sync/download?since=<timestamp>    │
       ├────────────────────────────────────────────────>│
       │                                                  │
       │                     5. Query all entities where  │
       │                        updated_at > since        │
       │                        and user_id = current     │
       │                                                  │
       │  6. Response: {tasks: [...], categories: [...]}  │
       │<────────────────────────────────────────────────┤
       │                                                  │
       │  7. Merge downloaded data with local             │
       │     Apply same LWW logic locally                 │
       │                                                  │
```

### Upload Logic (Pseudocode)

```javascript
async function handleSyncUpload(userId, deviceId, data) {
  const db = await getDatabase();
  const stats = { uploaded: {}, conflicts: {} };

  // Start transaction
  await db.run('BEGIN TRANSACTION');

  try {
    // Process each entity type
    for (const entityType of ['categories', 'tasks', 'notification_settings', 'shopping_lists', 'shopping_items']) {
      const entities = data[entityType] || [];
      stats.uploaded[entityType] = 0;
      stats.conflicts[entityType] = 0;

      for (const entity of entities) {
        // Find existing entity by user_id, device_id, client_id
        const existing = await db.get(
          `SELECT * FROM ${entityType}
           WHERE user_id = ? AND device_id = ? AND client_id = ?`,
          [userId, deviceId, entity.client_id]
        );

        if (existing) {
          // Conflict resolution: Last-Write-Wins
          if (entity.updated_at > existing.updated_at) {
            // Client is newer, update server
            await updateEntity(db, entityType, userId, deviceId, entity);
            stats.uploaded[entityType]++;
          } else if (entity.updated_at < existing.updated_at) {
            // Server is newer, mark as conflict for client to pull
            stats.conflicts[entityType]++;
          } else {
            // Same timestamp, no action needed
          }
        } else {
          // New entity, insert
          await insertEntity(db, entityType, userId, deviceId, entity);
          stats.uploaded[entityType]++;
        }
      }
    }

    // Process auto_delete_settings separately (one per user+device)
    if (data.auto_delete_settings) {
      await upsertAutoDeleteSettings(db, userId, deviceId, data.auto_delete_settings);
    }

    // Update sync metadata
    await updateSyncMetadata(db, userId, deviceId, 'upload', 'success');

    // Commit transaction
    await db.run('COMMIT');

    return { success: true, stats };

  } catch (error) {
    // Rollback on error
    await db.run('ROLLBACK');
    await updateSyncMetadata(db, userId, deviceId, 'upload', 'failed', error.message);
    throw error;
  }
}
```

### Download Logic (Pseudocode)

```javascript
async function handleSyncDownload(userId, deviceId, sinceTimestamp = 0) {
  const db = await getDatabase();
  const data = {};

  try {
    // Fetch all entity types
    const entityTypes = ['categories', 'tasks', 'notification_settings', 'shopping_lists', 'shopping_items'];

    for (const entityType of entityTypes) {
      // Get all entities for user updated since timestamp
      // Include entities from ALL devices (not just current device)
      data[entityType] = await db.all(
        `SELECT * FROM ${entityType}
         WHERE user_id = ? AND updated_at > ?
         ORDER BY updated_at ASC`,
        [userId, sinceTimestamp]
      );
    }

    // Get auto_delete_settings
    data.auto_delete_settings = await db.get(
      `SELECT * FROM auto_delete_settings
       WHERE user_id = ? AND device_id = ?`,
      [userId, deviceId]
    );

    // Update sync metadata
    await updateSyncMetadata(db, userId, deviceId, 'download', 'success');

    // Add server timestamp
    data.sync_timestamp = Math.floor(Date.now() / 1000);

    return { success: true, data };

  } catch (error) {
    await updateSyncMetadata(db, userId, deviceId, 'download', 'failed', error.message);
    throw error;
  }
}
```

### Conflict Resolution Strategy

**Last-Write-Wins (LWW):**
1. Compare `updated_at` timestamps of client and server entities
2. Entity with newer timestamp is considered authoritative
3. Older entity is overwritten
4. Ties (same timestamp) result in no change

**Advantages:**
- Simple to implement and understand
- Deterministic and predictable
- No user intervention required
- Works well for single-user scenarios

**Limitations:**
- May lose concurrent edits from different devices
- No merge of conflicting fields
- Assumes device clocks are reasonably synchronized

**Future Enhancements:**
- Operational Transform (OT) for text fields
- Conflict detection with manual resolution
- Vector clocks for true causality tracking
- Field-level merging instead of entity-level

### Soft Delete Handling

Soft deletes ensure deleted entities sync across devices:

```javascript
// When client deletes an entity
const deletedEntity = {
  client_id: 1,
  deleted: 1,
  deleted_at: Math.floor(Date.now() / 1000),
  updated_at: Math.floor(Date.now() / 1000)
};

// Server marks as deleted but keeps in database
UPDATE tasks
SET deleted = 1,
    deleted_at = ?,
    updated_at = ?
WHERE user_id = ? AND device_id = ? AND client_id = ?;

// On download, client receives deleted entities
// Client then marks them as deleted locally or purges
```

---

## Web UI Dashboard

### Dashboard Overview

A lightweight, real-time web dashboard for monitoring server health, user activity, and sync statistics.

**Features:**
- Real-time metrics via WebSocket
- Responsive single-page design
- No build process (vanilla HTML/CSS/JS)
- Minimal resource usage (<5MB RAM)
- Auto-refresh every 30 seconds

### Dashboard Components

#### 1. Server Status Panel
- Server uptime
- Memory usage
- CPU usage
- Database size
- API version

#### 2. User Statistics Panel
- Total users
- Active users (last 24h)
- New users (last 7 days)
- User growth chart (last 30 days)

#### 3. Device Statistics Panel
- Total devices
- Active devices (last 24h)
- Devices by type (pie chart)
- Device list with last seen

#### 4. Sync Activity Panel
- Total syncs today
- Successful vs failed syncs
- Average sync duration
- Sync timeline chart (last 24h)
- Recent sync errors

#### 5. Database Statistics Panel
- Total tasks
- Completed tasks (percentage)
- Total categories
- Total shopping lists
- Database growth trend

### Technology Stack

**Frontend:**
- HTML5
- CSS3 (no frameworks, custom responsive design)
- Vanilla JavaScript (ES6+)
- Chart.js for visualizations
- WebSocket for real-time updates

**Backend Integration:**
- WebSocket server (Socket.io)
- REST API endpoints for initial data load
- Server-Sent Events as fallback

### Dashboard File Structure

```
public/
├── index.html              # Main dashboard page
├── css/
│   └── dashboard.css       # Custom styles
├── js/
│   ├── dashboard.js        # Main dashboard logic
│   ├── charts.js           # Chart rendering
│   ├── websocket.js        # WebSocket connection
│   └── utils.js            # Utility functions
└── assets/
    ├── logo.png
    └── favicon.ico
```

### Dashboard HTML Structure

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Todo Sync Server Dashboard</title>
  <link rel="stylesheet" href="/css/dashboard.css">
</head>
<body>
  <header>
    <h1>Todo Sync Server Dashboard</h1>
    <div class="status-indicator">
      <span class="status-dot online"></span>
      <span>Server Online</span>
    </div>
  </header>

  <main class="dashboard-grid">
    <!-- Server Status Panel -->
    <section class="panel server-status">
      <h2>Server Status</h2>
      <div class="metrics">
        <div class="metric">
          <span class="label">Uptime</span>
          <span class="value" id="uptime">Loading...</span>
        </div>
        <div class="metric">
          <span class="label">Memory</span>
          <span class="value" id="memory">Loading...</span>
        </div>
        <div class="metric">
          <span class="label">CPU</span>
          <span class="value" id="cpu">Loading...</span>
        </div>
        <div class="metric">
          <span class="label">Database Size</span>
          <span class="value" id="db-size">Loading...</span>
        </div>
      </div>
    </section>

    <!-- User Statistics Panel -->
    <section class="panel user-stats">
      <h2>Users</h2>
      <div class="stats-grid">
        <div class="stat-card">
          <div class="stat-number" id="total-users">0</div>
          <div class="stat-label">Total Users</div>
        </div>
        <div class="stat-card">
          <div class="stat-number" id="active-users">0</div>
          <div class="stat-label">Active (24h)</div>
        </div>
        <div class="stat-card">
          <div class="stat-number" id="new-users">0</div>
          <div class="stat-label">New (7d)</div>
        </div>
      </div>
      <canvas id="user-growth-chart"></canvas>
    </section>

    <!-- Device Statistics Panel -->
    <section class="panel device-stats">
      <h2>Devices</h2>
      <div class="stats-grid">
        <div class="stat-card">
          <div class="stat-number" id="total-devices">0</div>
          <div class="stat-label">Total Devices</div>
        </div>
        <div class="stat-card">
          <div class="stat-number" id="active-devices">0</div>
          <div class="stat-label">Active (24h)</div>
        </div>
      </div>
      <canvas id="device-type-chart"></canvas>
    </section>

    <!-- Sync Activity Panel -->
    <section class="panel sync-activity">
      <h2>Sync Activity</h2>
      <div class="stats-grid">
        <div class="stat-card">
          <div class="stat-number" id="total-syncs">0</div>
          <div class="stat-label">Syncs Today</div>
        </div>
        <div class="stat-card">
          <div class="stat-number" id="success-rate">0%</div>
          <div class="stat-label">Success Rate</div>
        </div>
        <div class="stat-card">
          <div class="stat-number" id="avg-duration">0ms</div>
          <div class="stat-label">Avg Duration</div>
        </div>
      </div>
      <canvas id="sync-timeline-chart"></canvas>
    </section>

    <!-- Database Statistics Panel -->
    <section class="panel db-stats">
      <h2>Database</h2>
      <div class="stats-grid">
        <div class="stat-card">
          <div class="stat-number" id="total-tasks">0</div>
          <div class="stat-label">Total Tasks</div>
        </div>
        <div class="stat-card">
          <div class="stat-number" id="completed-tasks">0%</div>
          <div class="stat-label">Completed</div>
        </div>
        <div class="stat-card">
          <div class="stat-number" id="total-categories">0</div>
          <div class="stat-label">Categories</div>
        </div>
      </div>
    </section>

    <!-- Recent Activity Log -->
    <section class="panel activity-log">
      <h2>Recent Activity</h2>
      <div id="activity-list" class="activity-list">
        <!-- Populated dynamically -->
      </div>
    </section>
  </main>

  <footer>
    <p>Last updated: <span id="last-update">Never</span></p>
  </footer>

  <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>
  <script src="/js/websocket.js"></script>
  <script src="/js/charts.js"></script>
  <script src="/js/dashboard.js"></script>
</body>
</html>
```

### WebSocket Integration

```javascript
// public/js/websocket.js

class DashboardWebSocket {
  constructor(url) {
    this.url = url;
    this.socket = null;
    this.reconnectAttempts = 0;
    this.maxReconnectAttempts = 5;
    this.reconnectDelay = 3000;
  }

  connect() {
    this.socket = new WebSocket(this.url);

    this.socket.onopen = () => {
      console.log('WebSocket connected');
      this.reconnectAttempts = 0;
      this.updateConnectionStatus('online');
    };

    this.socket.onmessage = (event) => {
      const data = JSON.parse(event.data);
      this.handleMessage(data);
    };

    this.socket.onerror = (error) => {
      console.error('WebSocket error:', error);
      this.updateConnectionStatus('error');
    };

    this.socket.onclose = () => {
      console.log('WebSocket disconnected');
      this.updateConnectionStatus('offline');
      this.attemptReconnect();
    };
  }

  handleMessage(data) {
    switch (data.type) {
      case 'stats_update':
        window.updateDashboardStats(data.payload);
        break;
      case 'activity_log':
        window.addActivityLog(data.payload);
        break;
      case 'alert':
        window.showAlert(data.payload);
        break;
    }
  }

  attemptReconnect() {
    if (this.reconnectAttempts < this.maxReconnectAttempts) {
      this.reconnectAttempts++;
      setTimeout(() => {
        console.log(`Reconnecting... (${this.reconnectAttempts}/${this.maxReconnectAttempts})`);
        this.connect();
      }, this.reconnectDelay);
    }
  }

  updateConnectionStatus(status) {
    const indicator = document.querySelector('.status-dot');
    indicator.className = `status-dot ${status}`;
  }

  send(data) {
    if (this.socket && this.socket.readyState === WebSocket.OPEN) {
      this.socket.send(JSON.stringify(data));
    }
  }

  disconnect() {
    if (this.socket) {
      this.socket.close();
    }
  }
}

// Initialize WebSocket connection
const ws = new DashboardWebSocket('wss://localhost:8443/ws/dashboard');
ws.connect();
```

### Dashboard Backend Endpoints

```javascript
// controllers/adminController.js

const os = require('os');
const db = require('../database/connection');

exports.getDashboardStats = async (req, res) => {
  try {
    const stats = {
      server: {
        uptime: process.uptime(),
        memory: process.memoryUsage(),
        cpu: os.loadavg(),
        version: process.env.npm_package_version
      },
      users: await getUserStats(),
      devices: await getDeviceStats(),
      syncs: await getSyncStats(),
      database: await getDatabaseStats()
    };

    res.json({ success: true, data: stats });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};

async function getUserStats() {
  const total = await db.get('SELECT COUNT(*) as count FROM users WHERE is_active = 1');
  const activeToday = await db.get(
    'SELECT COUNT(*) as count FROM users WHERE last_login_at > ?',
    [Math.floor(Date.now() / 1000) - 86400]
  );
  const newThisWeek = await db.get(
    'SELECT COUNT(*) as count FROM users WHERE created_at > ?',
    [Math.floor(Date.now() / 1000) - 604800]
  );

  return {
    total: total.count,
    active_today: activeToday.count,
    new_this_week: newThisWeek.count
  };
}

async function getDeviceStats() {
  const total = await db.get('SELECT COUNT(*) as count FROM devices WHERE is_active = 1');
  const activeToday = await db.get(
    'SELECT COUNT(*) as count FROM devices WHERE last_seen_at > ?',
    [Math.floor(Date.now() / 1000) - 86400]
  );
  const byType = await db.all(
    'SELECT device_type, COUNT(*) as count FROM devices WHERE is_active = 1 GROUP BY device_type'
  );

  return {
    total: total.count,
    active_today: activeToday.count,
    by_type: byType.reduce((acc, row) => {
      acc[row.device_type || 'unknown'] = row.count;
      return acc;
    }, {})
  };
}

async function getSyncStats() {
  const today = Math.floor(Date.now() / 1000) - 86400;

  const totalToday = await db.get(
    'SELECT SUM(sync_count) as count FROM sync_metadata WHERE last_sync_at > ?',
    [today]
  );

  const successful = await db.get(
    'SELECT COUNT(*) as count FROM sync_metadata WHERE last_sync_at > ? AND last_sync_status = "success"',
    [today]
  );

  const failed = await db.get(
    'SELECT COUNT(*) as count FROM sync_metadata WHERE last_sync_at > ? AND last_sync_status = "failed"',
    [today]
  );

  return {
    total_today: totalToday.count || 0,
    successful: successful.count || 0,
    failed: failed.count || 0,
    success_rate: ((successful.count / (totalToday.count || 1)) * 100).toFixed(2)
  };
}

async function getDatabaseStats() {
  const tasks = await db.get('SELECT COUNT(*) as count FROM tasks WHERE deleted = 0');
  const completedTasks = await db.get('SELECT COUNT(*) as count FROM tasks WHERE deleted = 0 AND is_completed = 1');
  const categories = await db.get('SELECT COUNT(*) as count FROM categories WHERE deleted = 0');
  const shoppingLists = await db.get('SELECT COUNT(*) as count FROM shopping_lists WHERE deleted = 0');

  return {
    tasks_count: tasks.count,
    completed_tasks_count: completedTasks.count,
    completion_rate: ((completedTasks.count / (tasks.count || 1)) * 100).toFixed(2),
    categories_count: categories.count,
    shopping_lists_count: shoppingLists.count,
    size_mb: await getDatabaseSize()
  };
}

async function getDatabaseSize() {
  const fs = require('fs');
  const dbPath = process.env.DATABASE_PATH || './data/todo-sync.db';
  const stats = fs.statSync(dbPath);
  return (stats.size / (1024 * 1024)).toFixed(2);
}
```

---

## Deployment & Operations

### System Setup

#### 1. Ubuntu Server Preparation

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Node.js 20.x LTS
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# Verify installation
node --version  # Should be v20.x
npm --version

# Install PM2 globally
sudo npm install -g pm2

# Install build essentials (for native modules like bcrypt)
sudo apt install -y build-essential python3

# Create dedicated user
sudo useradd -r -s /bin/bash -d /opt/todo-sync-server -m todo-sync

# Create necessary directories
sudo mkdir -p /opt/todo-sync-server/{ssl,data,logs}
sudo chown -R todo-sync:todo-sync /opt/todo-sync-server
```

#### 2. Project Installation

```bash
# Switch to todo-sync user
sudo su - todo-sync

# Clone or copy project files to /opt/todo-sync-server
cd /opt/todo-sync-server

# Install dependencies
npm install --production

# Generate SSL certificate
bash ssl/generate-cert.sh

# Generate JWT secret
bash scripts/generate-jwt-secret.sh >> .env

# Copy environment template
cp .env.example .env

# Edit .env with your configuration
nano .env
```

#### 3. Environment Configuration

Create `.env` file:

```bash
# Server Configuration
NODE_ENV=production
PORT=8443
HOST=0.0.0.0

# JWT Configuration
JWT_SECRET=<generate-with-script>
JWT_EXPIRES_IN=7d

# Database Configuration
DATABASE_PATH=./data/todo-sync.db

# Security Configuration
BCRYPT_ROUNDS=12
ALLOWED_ORIGINS=*

# SSL Configuration
SSL_CERT_PATH=./ssl/cert.pem
SSL_KEY_PATH=./ssl/key.pem

# Logging Configuration
LOG_LEVEL=info
LOG_MAX_SIZE=20m
LOG_MAX_FILES=14d

# Dashboard Configuration
DASHBOARD_PORT=3000
DASHBOARD_ENABLED=true

# Rate Limiting
AUTH_RATE_LIMIT_MAX=5
AUTH_RATE_LIMIT_WINDOW=15
API_RATE_LIMIT_MAX=30
API_RATE_LIMIT_WINDOW=1
```

#### 4. Database Initialization

```bash
# Run database migrations
npm run migrate

# (Optional) Seed development data
npm run seed
```

#### 5. Systemd Service Setup

Create `/etc/systemd/system/todo-sync-server.service`:

```ini
[Unit]
Description=Todo Sync Server
Documentation=https://github.com/yourusername/todo-sync-server
After=network.target

[Service]
Type=simple
User=todo-sync
Group=todo-sync
WorkingDirectory=/opt/todo-sync-server
Environment=NODE_ENV=production
ExecStart=/usr/bin/node /opt/todo-sync-server/server.js
Restart=on-failure
RestartSec=10s
StandardOutput=journal
StandardError=journal
SyslogIdentifier=todo-sync

# Security hardening
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/opt/todo-sync-server/data /opt/todo-sync-server/logs
CapabilityBoundingSet=CAP_NET_BIND_SERVICE

# Resource limits
LimitNOFILE=65536
LimitNPROC=512

[Install]
WantedBy=multi-user.target
```

Enable and start service:

```bash
sudo systemctl daemon-reload
sudo systemctl enable todo-sync-server
sudo systemctl start todo-sync-server
sudo systemctl status todo-sync-server
```

#### 6. PM2 Alternative (Recommended for Easier Management)

```bash
# Start with PM2
pm2 start ecosystem.config.js

# Save PM2 process list
pm2 save

# Setup PM2 startup script
pm2 startup systemd -u todo-sync --hp /opt/todo-sync-server

# Monitor
pm2 monit

# View logs
pm2 logs todo-sync-server
```

**ecosystem.config.js:**

```javascript
module.exports = {
  apps: [{
    name: 'todo-sync-server',
    script: './server.js',
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '1G',
    env: {
      NODE_ENV: 'production'
    },
    error_file: './logs/pm2-error.log',
    out_file: './logs/pm2-out.log',
    log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
    merge_logs: true,
    min_uptime: '10s',
    max_restarts: 10
  }]
};
```

### Backup & Recovery

#### Automated Backup Script

Create `scripts/backup.sh`:

```bash
#!/bin/bash

# Configuration
BACKUP_DIR="/opt/todo-sync-server/backups"
DB_PATH="/opt/todo-sync-server/data/todo-sync.db"
SSL_DIR="/opt/todo-sync-server/ssl"
RETENTION_DAYS=30
COMPRESS_AFTER_DAYS=7

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Generate backup filename with timestamp
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_NAME="backup_${TIMESTAMP}"
BACKUP_PATH="${BACKUP_DIR}/${BACKUP_NAME}"

echo "[$(date)] Starting backup: $BACKUP_NAME"

# Create backup directory
mkdir -p "$BACKUP_PATH"

# Backup database
echo "[$(date)] Backing up database..."
cp "$DB_PATH" "${BACKUP_PATH}/todo-sync.db"

# Backup SSL certificates
echo "[$(date)] Backing up SSL certificates..."
cp -r "$SSL_DIR" "${BACKUP_PATH}/"

# Backup .env file
echo "[$(date)] Backing up configuration..."
cp /opt/todo-sync-server/.env "${BACKUP_PATH}/"

# Create checksum
echo "[$(date)] Creating checksum..."
cd "$BACKUP_PATH"
sha256sum * > checksums.txt

# Compress backups older than 7 days
echo "[$(date)] Compressing old backups..."
find "$BACKUP_DIR" -maxdepth 1 -type d -name "backup_*" -mtime +$COMPRESS_AFTER_DAYS ! -name "*.tar.gz" -exec tar -czf {}.tar.gz {} \; -exec rm -rf {} \;

# Delete backups older than retention period
echo "[$(date)] Cleaning up old backups..."
find "$BACKUP_DIR" -name "backup_*.tar.gz" -mtime +$RETENTION_DAYS -delete

echo "[$(date)] Backup completed: $BACKUP_NAME"

# Log backup to database
sqlite3 "$DB_PATH" "INSERT INTO server_stats (metric_name, metric_value) VALUES ('backup_completed', '${TIMESTAMP}')"
```

Make executable and add to cron:

```bash
chmod +x scripts/backup.sh

# Add to crontab (daily at 2 AM)
crontab -e
```

Add line:
```
0 2 * * * /opt/todo-sync-server/scripts/backup.sh >> /opt/todo-sync-server/logs/backup.log 2>&1
```

#### Restore from Backup

Create `scripts/restore.sh`:

```bash
#!/bin/bash

if [ $# -eq 0 ]; then
    echo "Usage: $0 <backup_name>"
    echo "Available backups:"
    ls -1 /opt/todo-sync-server/backups/
    exit 1
fi

BACKUP_NAME=$1
BACKUP_DIR="/opt/todo-sync-server/backups"
BACKUP_PATH="${BACKUP_DIR}/${BACKUP_NAME}"

# Check if backup exists
if [ ! -d "$BACKUP_PATH" ] && [ ! -f "${BACKUP_PATH}.tar.gz" ]; then
    echo "Error: Backup not found: $BACKUP_NAME"
    exit 1
fi

# Extract if compressed
if [ -f "${BACKUP_PATH}.tar.gz" ]; then
    echo "Extracting backup..."
    tar -xzf "${BACKUP_PATH}.tar.gz" -C "$BACKUP_DIR"
fi

# Verify checksums
echo "Verifying backup integrity..."
cd "$BACKUP_PATH"
sha256sum -c checksums.txt || { echo "Checksum verification failed!"; exit 1; }

# Stop server
echo "Stopping server..."
pm2 stop todo-sync-server

# Restore database
echo "Restoring database..."
cp "${BACKUP_PATH}/todo-sync.db" /opt/todo-sync-server/data/

# Restore SSL
echo "Restoring SSL certificates..."
cp -r "${BACKUP_PATH}/ssl" /opt/todo-sync-server/

# Restore config
echo "Restoring configuration..."
cp "${BACKUP_PATH}/.env" /opt/todo-sync-server/

# Start server
echo "Starting server..."
pm2 start todo-sync-server

echo "Restore completed from: $BACKUP_NAME"
```

### Monitoring & Logging

#### Log Files

All logs are written to `/opt/todo-sync-server/logs/`:

- `error.log` - Error level logs only
- `combined.log` - All log levels
- `access.log` - HTTP request logs
- `backup.log` - Backup script logs
- `pm2-error.log` - PM2 error logs
- `pm2-out.log` - PM2 stdout logs

#### Viewing Logs

```bash
# Real-time error logs
tail -f logs/error.log

# Real-time combined logs
tail -f logs/combined.log

# Search for errors
grep "ERROR" logs/combined.log

# Last 100 lines
tail -n 100 logs/combined.log

# PM2 logs
pm2 logs todo-sync-server --lines 100
```

#### Log Rotation

Winston handles daily log rotation automatically. Old logs are compressed and deleted after retention period.

### Firewall Configuration

```bash
# Allow HTTPS (8443)
sudo ufw allow 8443/tcp comment 'Todo Sync Server HTTPS'

# Allow Dashboard (3000) - Only from VPN/local network
sudo ufw allow from 10.0.0.0/24 to any port 3000 comment 'Dashboard (VPN only)'

# Enable firewall
sudo ufw enable

# Check status
sudo ufw status
```

### Nginx Reverse Proxy (Optional)

For production, consider using Nginx as reverse proxy:

```nginx
upstream todo_sync_backend {
    server localhost:8443;
    keepalive 64;
}

server {
    listen 443 ssl http2;
    server_name sync.yourdomain.com;

    ssl_certificate /etc/letsencrypt/live/sync.yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/sync.yourdomain.com/privkey.pem;

    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "DENY" always;
    add_header X-Content-Type-Options "nosniff" always;

    # Rate limiting
    limit_req_zone $binary_remote_addr zone=api_limit:10m rate=30r/m;
    limit_req zone=api_limit burst=10 nodelay;

    location / {
        proxy_pass https://todo_sync_backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    # WebSocket support
    location /ws/ {
        proxy_pass https://todo_sync_backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_read_timeout 86400;
    }
}
```

---

## Testing Strategy

### Unit Tests

Test individual functions and modules in isolation.

**Example: User Model Test**

```javascript
// tests/unit/models/User.test.js

const User = require('../../../models/User');
const db = require('../../../database/connection');

describe('User Model', () => {
  beforeAll(async () => {
    // Setup test database
    await db.migrate();
  });

  afterAll(async () => {
    // Cleanup
    await db.close();
  });

  describe('create', () => {
    it('should create a new user with hashed password', async () => {
      const userData = {
        username: 'testuser',
        email: 'test@example.com',
        password: 'TestPass123!'
      };

      const user = await User.create(userData);

      expect(user).toHaveProperty('id');
      expect(user.username).toBe('testuser');
      expect(user.email).toBe('test@example.com');
      expect(user.password_hash).not.toBe('TestPass123!');
    });

    it('should throw error for duplicate username', async () => {
      const userData = {
        username: 'testuser',
        email: 'test2@example.com',
        password: 'TestPass123!'
      };

      await expect(User.create(userData)).rejects.toThrow('Username already exists');
    });
  });

  describe('verifyPassword', () => {
    it('should return true for correct password', async () => {
      const user = await User.findByUsername('testuser');
      const isValid = await User.verifyPassword('TestPass123!', user.password_hash);
      expect(isValid).toBe(true);
    });

    it('should return false for incorrect password', async () => {
      const user = await User.findByUsername('testuser');
      const isValid = await User.verifyPassword('WrongPass', user.password_hash);
      expect(isValid).toBe(false);
    });
  });
});
```

### Integration Tests

Test API endpoints end-to-end.

**Example: Auth API Test**

```javascript
// tests/integration/auth.test.js

const request = require('supertest');
const app = require('../../server');
const db = require('../../database/connection');

describe('Auth API', () => {
  beforeAll(async () => {
    await db.migrate();
  });

  afterAll(async () => {
    await db.close();
  });

  describe('POST /api/auth/register', () => {
    it('should register a new user', async () => {
      const response = await request(app)
        .post('/api/auth/register')
        .send({
          username: 'newuser',
          email: 'newuser@example.com',
          password: 'SecurePass123!'
        });

      expect(response.status).toBe(201);
      expect(response.body.success).toBe(true);
      expect(response.body.data.user).toHaveProperty('id');
      expect(response.body.data.user.username).toBe('newuser');
    });

    it('should reject weak password', async () => {
      const response = await request(app)
        .post('/api/auth/register')
        .send({
          username: 'weakuser',
          email: 'weak@example.com',
          password: 'weak'
        });

      expect(response.status).toBe(400);
      expect(response.body.success).toBe(false);
    });
  });

  describe('POST /api/auth/login', () => {
    it('should login with valid credentials', async () => {
      const response = await request(app)
        .post('/api/auth/login')
        .send({
          username: 'newuser',
          password: 'SecurePass123!',
          device_id: 'test-device-123',
          device_name: 'Test Device',
          device_type: 'test'
        });

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveProperty('token');
      expect(response.body.data).toHaveProperty('expires_at');
    });

    it('should reject invalid credentials', async () => {
      const response = await request(app)
        .post('/api/auth/login')
        .send({
          username: 'newuser',
          password: 'WrongPassword',
          device_id: 'test-device-123',
          device_name: 'Test Device'
        });

      expect(response.status).toBe(401);
      expect(response.body.success).toBe(false);
    });
  });
});
```

### Running Tests

```bash
# Run all tests
npm test

# Run unit tests only
npm run test:unit

# Run integration tests only
npm run test:integration

# Run with coverage
npm run test:coverage

# Run in watch mode
npm run test:watch
```

**package.json scripts:**

```json
{
  "scripts": {
    "test": "jest --coverage",
    "test:unit": "jest tests/unit",
    "test:integration": "jest tests/integration",
    "test:coverage": "jest --coverage --coverageReporters=text-lcov | coveralls",
    "test:watch": "jest --watch"
  }
}
```

---

## Performance & Optimization

### Database Optimization

1. **Indexes**: Strategic indexes on frequently queried columns
2. **WAL Mode**: Better concurrency for SQLite
3. **Prepared Statements**: Faster repeated queries
4. **Batch Operations**: Reduce transaction overhead
5. **Connection Pooling**: Reuse connections

### API Optimization

1. **Compression**: Gzip responses (compression middleware)
2. **Caching**: Cache expensive queries (Redis optional)
3. **Pagination**: Limit large result sets
4. **Selective Fields**: Return only requested fields
5. **ETag Support**: HTTP caching for unchanged data

### Resource Management

**Expected Resource Usage:**
- Idle: ~50MB RAM, <1% CPU
- Light load (10 active users): ~100MB RAM, ~5% CPU
- Medium load (50 active users): ~200MB RAM, ~15% CPU
- Peak load (100 active users): ~400MB RAM, ~30% CPU

**Scaling Strategies:**
- Vertical: Increase VM RAM/CPU (up to 4GB/4 cores)
- Horizontal: Add PM2 cluster mode (multiple Node processes)
- Database: Migrate to PostgreSQL if >10,000 users
- Caching: Add Redis for session/query caching

---

## Security Checklist

- [x] HTTPS enforced (self-signed or Let's Encrypt)
- [x] JWT authentication on all protected routes
- [x] Bcrypt password hashing (12+ rounds)
- [x] Input validation and sanitization
- [x] SQL injection prevention (parameterized queries)
- [x] Rate limiting on all endpoints
- [x] CORS properly configured
- [x] Security headers (Helmet.js)
- [x] No sensitive data in error messages
- [x] No .env or secrets in git
- [x] Database backups encrypted
- [x] Regular security updates (dependabot)
- [x] Audit logging of auth events
- [x] API token rotation support
- [x] Device management and revocation

---

## Implementation Checklist

### Phase 1: Core Setup (Day 1)
- [ ] Create project structure
- [ ] Initialize npm and install dependencies
- [ ] Configure ESLint and Prettier
- [ ] Setup .gitignore and .env.example
- [ ] Generate SSL certificates
- [ ] Create database schema
- [ ] Implement database connection

### Phase 2: Authentication (Day 2)
- [ ] Implement User model
- [ ] Implement Device model
- [ ] Implement ApiToken model
- [ ] Create auth routes and controller
- [ ] Implement JWT middleware
- [ ] Add password validation
- [ ] Test authentication flow

### Phase 3: Sync Logic (Day 3)
- [ ] Implement Task model
- [ ] Implement Category model
- [ ] Implement NotificationSettings model
- [ ] Implement ShoppingList and ShoppingItem models
- [ ] Create sync routes and controller
- [ ] Implement upload logic with conflict resolution
- [ ] Implement download logic
- [ ] Test sync operations

### Phase 4: Security & Middleware (Day 4)
- [ ] Implement rate limiting
- [ ] Add input validation middleware
- [ ] Add sanitization middleware
- [ ] Implement error handler
- [ ] Add request logging (Morgan + Winston)
- [ ] Configure CORS
- [ ] Add Helmet security headers
- [ ] Test security measures

### Phase 5: Dashboard (Day 5)
- [ ] Create dashboard HTML/CSS
- [ ] Implement WebSocket server
- [ ] Create admin stats endpoints
- [ ] Implement real-time updates
- [ ] Add charts (Chart.js)
- [ ] Test dashboard functionality

### Phase 6: Deployment (Day 6)
- [ ] Create systemd service file
- [ ] Create PM2 ecosystem config
- [ ] Write backup script
- [ ] Write restore script
- [ ] Setup cron jobs
- [ ] Configure firewall
- [ ] Test deployment on Ubuntu server

### Phase 7: Testing & Documentation (Day 7)
- [ ] Write unit tests
- [ ] Write integration tests
- [ ] Create API documentation
- [ ] Write README.md
- [ ] Write DEPLOYMENT.md
- [ ] Write TROUBLESHOOTING.md
- [ ] Final security audit

---

## Success Metrics

**Technical Metrics:**
- Server uptime: >99.5%
- API response time: <100ms (p95)
- Sync completion rate: >99%
- Database size: Grows linearly with users
- Memory usage: Stays under 500MB with 100 concurrent users

**User Metrics:**
- Successful sync rate: >99.5%
- Average sync time: <500ms
- Zero data loss incidents
- User satisfaction with sync reliability

---

## Future Enhancements

### Short Term (1-3 months)
- [ ] End-to-end encryption for task data
- [ ] Real-time sync via WebSockets (instead of polling)
- [ ] Advanced conflict resolution (field-level merge)
- [ ] Shared task lists (family/team collaboration)
- [ ] File attachment support (images, documents)

### Medium Term (3-6 months)
- [ ] Mobile push notifications
- [ ] OAuth2 authentication (Google, Apple Sign-In)
- [ ] Multi-language support
- [ ] Advanced analytics and insights
- [ ] Automated testing and CI/CD pipeline

### Long Term (6-12 months)
- [ ] Horizontal scaling with load balancer
- [ ] PostgreSQL migration for better concurrency
- [ ] Redis caching layer
- [ ] Elasticsearch for full-text search
- [ ] GraphQL API alternative
- [ ] Public API for third-party integrations

---

## Conclusion

This implementation specification provides a complete blueprint for building a production-ready todo synchronization server. The architecture prioritizes:

1. **Simplicity**: Easy to understand, deploy, and maintain
2. **Security**: Multiple layers of protection for user data
3. **Performance**: Optimized for low resource usage
4. **Reliability**: Robust error handling and recovery
5. **Scalability**: Foundation supports future growth

The resulting server will be lightweight, secure, and capable of handling hundreds of concurrent users on modest hardware (2GB RAM, 2 CPU cores).

**Total estimated implementation time**: 5-7 days for experienced developer

**Estimated resource usage**:
- Disk: ~50MB for code + variable for data/logs
- RAM: 50-200MB typical, 500MB peak
- CPU: <5% typical, <30% peak
- Network: ~10KB per sync operation

**Deployment checklist completed**: Ready for production deployment after thorough testing.
