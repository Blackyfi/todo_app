# Todo Sync Server

A production-ready REST API server for synchronizing todo list data across multiple devices. Built with Node.js, Express, and SQLite for lightweight, efficient, and secure data synchronization.

## Features

- ✅ **RESTful API** - Clean, predictable API design
- 🔐 **JWT Authentication** - Secure stateless authentication
- 🔄 **Smart Sync** - Last-write-wins conflict resolution
- 📱 **Multi-Device** - Support for unlimited devices per user
- 💾 **SQLite Database** - Embedded, zero-config database
- 🚀 **High Performance** - Optimized for low resource usage
- 📊 **Web Dashboard** - Real-time monitoring and statistics
- 🔒 **Security Hardened** - Rate limiting, CORS, helmet, bcrypt
- 📝 **Comprehensive Logging** - Winston with daily log rotation
- 🛡️ **Error Handling** - Graceful error handling and recovery

## System Requirements

- **Node.js**: 18.x or higher
- **RAM**: 2GB minimum (server uses ~50-200MB)
- **Storage**: 10GB free space for data and logs
- **OS**: Ubuntu Server 24.04 LTS (or any Linux distribution)

## Quick Start

### 1. Installation

```bash
# Clone or navigate to server directory
cd /opt/todo_app/server

# Run automated setup script
bash scripts/setup.sh
```

The setup script will:
- Install Node.js dependencies
- Generate secure JWT secret
- Create SSL certificates
- Create .env configuration file
- Run database migrations

### 2. Configuration

Edit `.env` file to customize your settings:

```bash
nano .env
```

Key settings:
- `JWT_SECRET` - Auto-generated, keep secure
- `PORT` - Default 8443 (HTTPS)
- `ALLOWED_ORIGINS` - Comma-separated list of allowed CORS origins
- `LOG_LEVEL` - info (production) or debug (development)

### 3. Start Server

```bash
# Production (recommended with PM2)
pm2 start ecosystem.config.js
pm2 save
pm2 startup

# Or direct start
npm start

# Development (with auto-reload)
npm run dev
```

### 4. Verify Installation

```bash
# Check health endpoint
curl -k https://localhost:8443/api/health

# View dashboard
# Open https://localhost:8443/index.html in browser
```

## API Documentation

### Authentication

#### Register User
```http
POST /api/auth/register
Content-Type: application/json

{
  "username": "john_doe",
  "email": "john@example.com",
  "password": "SecurePass123!"
}
```

#### Login
```http
POST /api/auth/login
Content-Type: application/json

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

**Response:**
```json
{
  "success": true,
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "expires_at": 1704672000,
    "user": { "id": 1, "username": "john_doe" },
    "device": { "id": 1, "device_id": "...", "device_name": "..." }
  }
}
```

### Sync Operations

#### Upload Data
```http
POST /api/sync/upload
Authorization: Bearer <token>
Content-Type: application/json

{
  "device_id": "device-uuid-12345",
  "sync_timestamp": 1704672000,
  "data": {
    "categories": [...],
    "tasks": [...]
  }
}
```

#### Download Data
```http
GET /api/sync/download?device_id=device-uuid-12345&since=1704672000
Authorization: Bearer <token>
```

#### Sync Status
```http
GET /api/sync/status?device_id=device-uuid-12345
Authorization: Bearer <token>
```

### Device Management

#### List Devices
```http
GET /api/devices
Authorization: Bearer <token>
```

#### Unregister Device
```http
DELETE /api/devices/:deviceId
Authorization: Bearer <token>
```

### Health Check

```http
GET /api/health
```

## Database Management

### Migrations

```bash
# Run migrations
npm run migrate

# The database is automatically created at: data/todo-sync.db
```

### Backup

```bash
# Manual backup
bash scripts/backup.sh

# Setup automated daily backups (2 AM)
crontab -e
# Add line:
0 2 * * * /opt/todo_app/server/scripts/backup.sh >> /opt/todo_app/server/logs/backup.log 2>&1
```

Backups are stored in `/opt/todo_app/server/backups/` with:
- 30-day retention
- Automatic compression after 7 days
- SHA256 checksums for integrity verification

## Monitoring & Logging

### Dashboard

Access the web dashboard at `https://localhost:8443/index.html`

Features:
- Real-time server statistics
- User and device metrics
- Sync activity monitoring
- Database statistics
- Auto-refresh every 30 seconds

### Logs

Logs are stored in `/opt/todo_app/server/logs/`:

```bash
# View error logs
tail -f logs/error-*.log

# View all logs
tail -f logs/combined-*.log

# View PM2 logs
pm2 logs todo-sync-server
```

Log rotation:
- Daily rotation
- Maximum 20MB per file
- 14-day retention

## Security

### Best Practices

1. **Change Default JWT Secret**
   ```bash
   bash scripts/generate-jwt-secret.sh
   # Add output to .env file
   ```

2. **Use Let's Encrypt in Production**
   ```bash
   certbot certonly --standalone -d yourdomain.com
   # Update SSL_CERT_PATH and SSL_KEY_PATH in .env
   ```

3. **Configure Firewall**
   ```bash
   sudo ufw allow 8443/tcp
   sudo ufw enable
   ```

4. **Set ALLOWED_ORIGINS**
   ```bash
   # In .env, restrict CORS to your domains
   ALLOWED_ORIGINS=https://yourdomain.com,https://app.yourdomain.com
   ```

5. **Regular Updates**
   ```bash
   npm audit
   npm update
   ```

### Security Features

- ✅ HTTPS-only (TLS 1.2+)
- ✅ JWT with secure secrets
- ✅ Bcrypt password hashing (12 rounds)
- ✅ Rate limiting (5 req/min auth, 30 req/min API)
- ✅ Input validation and sanitization
- ✅ SQL injection prevention
- ✅ CORS protection
- ✅ Security headers (Helmet.js)
- ✅ No sensitive data in errors

## Deployment

### PM2 (Recommended)

```bash
# Install PM2
npm install -g pm2

# Start server
pm2 start ecosystem.config.js

# Save process list
pm2 save

# Setup startup script
pm2 startup

# Monitor
pm2 monit

# View logs
pm2 logs

# Restart
pm2 restart todo-sync-server

# Stop
pm2 stop todo-sync-server
```

### Systemd Service

Create `/etc/systemd/system/todo-sync-server.service`:

```ini
[Unit]
Description=Todo Sync Server
After=network.target

[Service]
Type=simple
User=your-user
WorkingDirectory=/opt/todo_app/server
Environment=NODE_ENV=production
ExecStart=/usr/bin/node /opt/todo_app/server/server.js
Restart=on-failure
RestartSec=10s

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable todo-sync-server
sudo systemctl start todo-sync-server
sudo systemctl status todo-sync-server
```

## Troubleshooting

### Common Issues

**Issue: EADDRINUSE - Port already in use**
```bash
# Find process using port 8443
sudo lsof -i :8443
# Kill the process
sudo kill -9 <PID>
```

**Issue: SSL certificate errors**
```bash
# Regenerate certificates
cd ssl && bash generate-cert.sh
```

**Issue: Database locked**
```bash
# Check if another process is using the database
lsof data/todo-sync.db
# Restart the server
pm2 restart todo-sync-server
```

**Issue: High memory usage**
```bash
# Check PM2 logs for errors
pm2 logs

# Restart server
pm2 restart todo-sync-server

# Check for database issues
sqlite3 data/todo-sync.db "PRAGMA integrity_check;"
```

### Debug Mode

```bash
# Set debug logging in .env
LOG_LEVEL=debug

# Restart server
pm2 restart todo-sync-server

# View detailed logs
pm2 logs --lines 100
```

## Performance Optimization

### Expected Performance

- **Idle**: ~50MB RAM, <1% CPU
- **Light (10 users)**: ~100MB RAM, ~5% CPU
- **Medium (50 users)**: ~200MB RAM, ~15% CPU
- **Heavy (100 users)**: ~400MB RAM, ~30% CPU

### Optimization Tips

1. **Enable SQLite WAL mode** (auto-enabled)
2. **Use PM2 cluster mode** for multiple CPU cores
3. **Add Redis caching** for frequently accessed data
4. **Implement database indexing** (already optimized)
5. **Use Nginx reverse proxy** for static files

## Development

### Project Structure

```
/opt/todo_app/server/
├── server.js              # Main entry point
├── config/                # Configuration files
├── controllers/           # Business logic
├── routes/                # API route definitions
├── middleware/            # Express middleware
├── models/                # Database models
├── database/              # Database connection & migrations
├── utils/                 # Utility functions
├── public/                # Dashboard static files
├── scripts/               # Deployment scripts
└── logs/                  # Application logs
```

### Running Tests

```bash
# Run all tests
npm test

# Run unit tests
npm run test:unit

# Run integration tests
npm run test:integration
```

### Code Quality

```bash
# Lint code
npm run lint

# Format code
npm run format
```

## Support

### Getting Help

1. Check logs: `pm2 logs todo-sync-server`
2. View health: `curl -k https://localhost:8443/api/health`
3. Check database: `sqlite3 data/todo-sync.db "SELECT * FROM users;"`
4. Review documentation in `/opt/todo_app/server/server_implementation.md`

## License

MIT License - see LICENSE file for details

## Version

Current version: 1.0.0

---

**Built with ❤️ using Node.js, Express, and SQLite**
