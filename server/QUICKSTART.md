# Todo Sync Server - Quick Start Guide

Get your todo sync server running in 5 minutes!

## Prerequisites

- Ubuntu Server 24.04 (or any Linux)
- Node.js 18+ installed
- 2GB RAM minimum

## Installation (One Command)

```bash
cd /opt/todo_app/server && bash scripts/setup.sh
```

## Start Server

```bash
# Option 1: Direct start (development)
npm start

# Option 2: With PM2 (production - recommended)
npm install -g pm2
pm2 start ecosystem.config.js
pm2 save
```

## Verify It Works

```bash
# Test health endpoint
curl -k https://localhost:8443/api/health

# Should see:
# {"success":true,"data":{"status":"healthy",...}}
```

## Access Dashboard

Open in browser: **https://localhost:8443/index.html**

(Click "Advanced" → "Proceed" for self-signed certificate warning)

## Test the API

### 1. Register a User

```bash
curl -k -X POST https://localhost:8443/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "password": "TestPass123!",
    "email": "test@example.com"
  }'
```

### 2. Login and Get Token

```bash
curl -k -X POST https://localhost:8443/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "password": "TestPass123!",
    "device_id": "test-device-123",
    "device_name": "My Test Device",
    "device_type": "test"
  }'
```

**Save the token from the response!**

### 3. Test Sync Upload

```bash
TOKEN="your-token-here"

curl -k -X POST https://localhost:8443/api/sync/upload \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "device_id": "test-device-123",
    "sync_timestamp": 1704672000,
    "data": {
      "categories": [],
      "tasks": [{
        "client_id": 1,
        "title": "Test Task",
        "description": "My first synced task",
        "priority": 1,
        "is_completed": 0,
        "updated_at": 1704672000,
        "deleted": 0
      }]
    }
  }'
```

### 4. Test Sync Download

```bash
curl -k -X GET "https://localhost:8443/api/sync/download?device_id=test-device-123" \
  -H "Authorization: Bearer $TOKEN"
```

## Common Commands

```bash
# View logs
pm2 logs todo-sync-server

# Or:
tail -f logs/combined-*.log

# Restart server
pm2 restart todo-sync-server

# Stop server
pm2 stop todo-sync-server

# Server status
pm2 status

# Manual backup
bash scripts/backup.sh
```

## Configuration

Edit `.env` file to customize:

```bash
nano .env
```

Important settings:
- `PORT=8443` - Server port
- `ALLOWED_ORIGINS=*` - CORS origins (restrict in production!)
- `LOG_LEVEL=info` - Logging verbosity

## Next Steps

1. ✅ Server running
2. ✅ API tested
3. 📱 **Configure Flutter app** to use this server
4. 🌐 **Expose via VPN** or port forwarding
5. 🔐 **Setup Let's Encrypt** for production SSL
6. 📊 **Monitor dashboard** for activity

## Troubleshooting

**Port already in use?**
```bash
sudo lsof -i :8443
sudo kill -9 <PID>
```

**Can't connect?**
```bash
# Check if server is running
pm2 status

# Check logs
pm2 logs

# Restart server
pm2 restart todo-sync-server
```

**Database issues?**
```bash
# Remove and recreate
rm data/todo-sync.db
npm run migrate
```

## Need Help?

- 📖 Full documentation: `README.md`
- 🔌 API documentation: `docs/API.md`
- 🛠️ Installation guide: `INSTALLATION.md`
- 📊 Implementation details: `IMPLEMENTATION_SUMMARY.md`

## Support

Check logs first:
```bash
# Error logs
tail -f logs/error-*.log

# All logs
tail -f logs/combined-*.log

# PM2 logs
pm2 logs
```

---

**You're all set! 🎉 Your todo sync server is running!**

Access dashboard: https://localhost:8443/index.html
