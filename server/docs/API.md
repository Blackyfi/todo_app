# Todo Sync Server API Documentation

Base URL: `https://localhost:8443/api`

All API responses follow this structure:

```json
{
  "success": true|false,
  "data": { ... },
  "message": "Optional message",
  "errors": [...]  // Only on validation errors
}
```

## Authentication

All endpoints except `/auth/register`, `/auth/login`, and `/health` require authentication via JWT token in the `Authorization` header:

```
Authorization: Bearer <your-jwt-token>
```

## Endpoints

### POST /auth/register
Register a new user account.

**Request Body:**
```json
{
  "username": "string (3-30 chars, alphanumeric + underscore)",
  "email": "string (valid email, optional)",
  "password": "string (min 8 chars, 1 upper, 1 lower, 1 number)"
}
```

**Success Response (201):**
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

---

### POST /auth/login
Authenticate user and receive JWT token.

**Request Body:**
```json
{
  "username": "string",
  "password": "string",
  "device_id": "string (unique device identifier)",
  "device_name": "string",
  "device_type": "string (android|ios|web|windows|macos|linux)",
  "app_version": "string (optional)",
  "os_version": "string (optional)"
}
```

**Success Response (200):**
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

### POST /auth/refresh
Refresh JWT token before expiration.

**Headers:** `Authorization: Bearer <old-token>`

**Request Body:**
```json
{
  "token": "string (current token)"
}
```

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "expires_at": 1705276800
  },
  "message": "Token refreshed successfully"
}
```

---

### POST /auth/logout
Logout user (client-side token invalidation).

**Headers:** `Authorization: Bearer <token>`

**Success Response (200):**
```json
{
  "success": true,
  "data": null,
  "message": "Logged out successfully"
}
```

---

### POST /sync/upload
Upload data changes from device to server.

**Headers:** `Authorization: Bearer <token>`

**Request Body:**
```json
{
  "device_id": "string",
  "sync_timestamp": "number (Unix timestamp)",
  "data": {
    "categories": [
      {
        "client_id": "number",
        "name": "string",
        "color": "number",
        "updated_at": "number",
        "deleted": "number (0 or 1)",
        "deleted_at": "number (optional)"
      }
    ],
    "tasks": [
      {
        "client_id": "number",
        "title": "string",
        "description": "string (optional)",
        "due_date": "number (optional)",
        "is_completed": "number (0 or 1)",
        "completed_at": "number (optional)",
        "category_id": "number (optional)",
        "priority": "number (0=low, 1=medium, 2=high)",
        "updated_at": "number",
        "deleted": "number (0 or 1)",
        "deleted_at": "number (optional)"
      }
    ]
  }
}
```

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "uploaded": {
      "categories": 5,
      "tasks": 12
    },
    "conflicts": {
      "categories": 0,
      "tasks": 1
    },
    "sync_timestamp": 1704672100
  },
  "message": "Data uploaded successfully"
}
```

---

### GET /sync/download
Download user data from server to device.

**Headers:** `Authorization: Bearer <token>`

**Query Parameters:**
- `device_id` (required): Device identifier
- `since` (optional): Unix timestamp for delta sync

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "categories": [ /* array of category objects */ ],
    "tasks": [ /* array of task objects */ ],
    "notification_settings": [],
    "shopping_lists": [],
    "shopping_items": [],
    "auto_delete_settings": null,
    "sync_timestamp": 1704672100
  }
}
```

---

### GET /sync/status
Get sync status for device.

**Headers:** `Authorization: Bearer <token>`

**Query Parameters:**
- `device_id` (required): Device identifier

**Success Response (200):**
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

### GET /devices
List all devices for authenticated user.

**Headers:** `Authorization: Bearer <token>`

**Success Response (200):**
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
      }
    ],
    "count": 1
  }
}
```

---

### DELETE /devices/:deviceId
Unregister a device.

**Headers:** `Authorization: Bearer <token>`

**URL Parameters:**
- `deviceId`: Device identifier to unregister

**Success Response (200):**
```json
{
  "success": true,
  "data": null,
  "message": "Device unregistered successfully"
}
```

---

### GET /health
Health check endpoint (no authentication required).

**Success Response (200):**
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

### GET /admin/stats
Get dashboard statistics (for admin dashboard).

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "server": {
      "uptime": "1d 2h 30m",
      "uptime_seconds": 95400,
      "memory_usage_mb": "145.23",
      "cpu_usage_percent": "8.5",
      "version": "1.0.0"
    },
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
      "success_rate": "98.71"
    },
    "database": {
      "size_mb": 12.5,
      "tasks_count": 1247,
      "completed_tasks_count": 789,
      "completion_rate": 63.27,
      "categories_count": 0,
      "shopping_lists_count": 0
    }
  }
}
```

## Error Responses

All errors follow this structure:

**400 Bad Request:**
```json
{
  "success": false,
  "message": "Validation error message"
}
```

**401 Unauthorized:**
```json
{
  "success": false,
  "message": "Authentication failed"
}
```

**404 Not Found:**
```json
{
  "success": false,
  "message": "Resource not found"
}
```

**409 Conflict:**
```json
{
  "success": false,
  "message": "Resource already exists"
}
```

**429 Too Many Requests:**
```json
{
  "success": false,
  "message": "Rate limit exceeded"
}
```

**500 Internal Server Error:**
```json
{
  "success": false,
  "message": "An unexpected error occurred"
}
```

## Rate Limits

- **Authentication endpoints** (`/auth/*`): 5 requests per 15 minutes
- **Sync endpoints** (`/sync/*`): 10 requests per minute
- **API endpoints** (general): 30 requests per minute

Rate limit headers are included in responses:
```
RateLimit-Limit: 30
RateLimit-Remaining: 25
RateLimit-Reset: 1704672100
```

## Pagination

Currently not implemented. All list endpoints return complete results.

## Filtering

Currently not implemented. Use query parameters for basic filtering:
- `/sync/download?since=<timestamp>` - Get changes since timestamp

## Versioning

API version is included in package.json and returned in health endpoint.
Current version: 1.0.0

Breaking changes will be communicated via:
1. Server logs
2. Health endpoint version field
3. API deprecation headers

## Best Practices

1. **Store JWT tokens securely** (encrypted storage on device)
2. **Refresh tokens** before expiration (7-day expiry)
3. **Handle rate limits** with exponential backoff
4. **Implement delta sync** using `since` parameter
5. **Batch operations** where possible
6. **Handle conflicts** gracefully (server uses last-write-wins)
7. **Validate data** before uploading
8. **Use HTTPS** always (self-signed cert in dev, Let's Encrypt in prod)

## Support

For issues or questions:
1. Check server logs: `/opt/todo_app/server/logs/`
2. Review README.md
3. Test with health endpoint
4. Check dashboard at `https://localhost:8443/index.html`
