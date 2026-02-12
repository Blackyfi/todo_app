#!/bin/bash

# Initial setup script for todo-sync-server

echo "=== Todo Sync Server Setup ==="
echo ""

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "✗ Node.js is not installed"
    echo "  Please install Node.js 18+ from https://nodejs.org"
    exit 1
fi

echo "✓ Node.js $(node --version) found"

# Install dependencies
echo ""
echo "Installing dependencies..."
npm install

# Create .env file from example
if [ ! -f .env ]; then
    echo ""
    echo "Creating .env file..."
    cp .env.example .env

    # Generate JWT secret
    echo ""
    echo "Generating JWT secret..."
    SECRET=$(openssl rand -hex 64)
    sed -i "s/your-super-secret-jwt-key-change-this-in-production/$SECRET/" .env

    echo "✓ .env file created with secure JWT secret"
else
    echo ""
    echo "⚠️  .env file already exists, skipping"
fi

# Generate SSL certificates
if [ ! -f ssl/cert.pem ]; then
    echo ""
    echo "Generating SSL certificates..."
    cd ssl && bash generate-cert.sh && cd ..
else
    echo ""
    echo "⚠️  SSL certificates already exist, skipping"
fi

# Create necessary directories
mkdir -p data logs backups

# Run database migrations
echo ""
echo "Running database migrations..."
npm run migrate

echo ""
echo "=== Setup Complete ==="
echo ""
echo "Next steps:"
echo "1. Review and update .env file with your configuration"
echo "2. Start the server:"
echo "   npm start              (production)"
echo "   npm run dev            (development with auto-reload)"
echo ""
echo "3. Access the dashboard at https://localhost:8443"
echo "4. API documentation: /opt/todo_app/server/docs/"
echo ""
