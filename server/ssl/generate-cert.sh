#!/bin/bash

# Generate self-signed SSL certificate for development/testing

echo "Generating self-signed SSL certificate..."

openssl req -x509 -newkey rsa:4096 -nodes \
  -keyout key.pem \
  -out cert.pem \
  -days 365 \
  -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost"

chmod 600 key.pem
chmod 644 cert.pem

echo ""
echo "✓ Self-signed SSL certificate generated successfully"
echo "  Certificate: ssl/cert.pem"
echo "  Private key: ssl/key.pem"
echo ""
echo "⚠️  This is a self-signed certificate for development only"
echo "For production, use Let's Encrypt:"
echo "  certbot certonly --standalone -d yourdomain.com"
