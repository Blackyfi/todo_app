# Todo Sync Server - Installation Guide

## Quick Installation (Recommended)

```bash
cd /opt/todo_app/server
bash scripts/setup.sh
```

This automated script will handle everything for you!

## Manual Installation

If you prefer manual setup, follow these steps:

### 1. Install Dependencies

```bash
cd /opt/todo_app/server
npm install
```

### 2. Generate Environment File

```bash
cp .env.example .env
```

### 3. Generate JWT Secret

```bash
bash scripts/generate-jwt-secret.sh
```

Copy the output and add to your `.env` file.

### 4. Generate SSL Certificates

```bash
cd ssl
bash generate-cert.sh
cd ..
```

### 5. Run Database Migrations

```bash
npm run migrate
```

### 6. Start the Server

```bash
# Development
npm run dev

# Production with PM2
pm2 start ecosystem.config.js
pm2 save
```

## Verification

### Test Health Endpoint

```bash
curl -k https://localhost:8443/api/health
```

Expected response:
```json
{
  "success": true,
  "data": {
    "status": "healthy",
    "timestamp": 1704672100,
    "uptime": 10,
    "version": "1.0.0",
    "database": "connected"
  }
}
```

### Access Dashboard

Open in browser: `https://localhost:8443/index.html`

(You'll see a security warning due to self-signed certificate - this is normal for development)

## Post-Installation

### 1. Configure Firewall

```bash
sudo ufw allow 8443/tcp
sudo ufw enable
```

### 2. Setup Automated Backups

```bash
crontab -e
# Add this line:
0 2 * * * /opt/todo_app/server/scripts/backup.sh >> /opt/todo_app/server/logs/backup.log 2>&1
```

### 3. Configure Production SSL (Optional)

For production, replace self-signed certificates with Let's Encrypt:

```bash
sudo apt install certbot
sudo certbot certonly --standalone -d yourdomain.com

# Update .env
SSL_CERT_PATH=/etc/letsencrypt/live/yourdomain.com/fullchain.pem
SSL_KEY_PATH=/etc/letsencrypt/live/yourdomain.com/privkey.pem
```

### 4. Set CORS Origins

In `.env`, restrict CORS to your domains:

```bash
ALLOWED_ORIGINS=https://yourdomain.com,https://app.yourdomain.com
```

## Testing the API

### Register a User

```bash
curl -k -X POST https://localhost:8443/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "email": "test@example.com",
    "password": "TestPass123!"
  }'
```

### Login

```bash
curl -k -X POST https://localhost:8443/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "password": "TestPass123!",
    "device_id": "test-device-123",
    "device_name": "Test Device",
    "device_type": "test"
  }'
```

Save the token from the response for authenticated requests.

### Test Sync Upload

```bash
TOKEN="<your-jwt-token-here>"

curl -k -X POST https://localhost:8443/api/sync/upload \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "device_id": "test-device-123",
    "sync_timestamp": 1704672000,
    "data": {
      "categories": [],
      "tasks": []
    }
  }'
```

## Troubleshooting

### Port Already in Use

```bash
sudo lsof -i :8443
sudo kill -9 <PID>
```

### Permission Errors

```bash
sudo chown -R $USER:$USER /opt/todo_app/server
chmod +x scripts/*.sh
chmod +x ssl/generate-cert.sh
```

### Database Issues

```bash
# Remove database and recreate
rm data/todo-sync.db
npm run migrate
```

### SSL Certificate Issues

```bash
cd ssl
rm *.pem
bash generate-cert.sh
cd ..
```

## Next Steps

1. ✅ Server is running
2. ✅ Dashboard accessible
3. ✅ API endpoints working
4. 📱 Configure Flutter app to connect to server
5. 🌐 Expose via VPN or port forwarding
6. 🔐 Setup production SSL certificate
7. 📊 Monitor via dashboard

## Support

- **Logs**: `tail -f logs/combined-*.log`
- **PM2 Status**: `pm2 status`
- **Database**: `sqlite3 data/todo-sync.db`
- **Documentation**: See README.md and docs/API.md

Congratulations! Your Todo Sync Server is ready! 🎉
