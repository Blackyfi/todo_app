#!/bin/bash

# Generate a secure JWT secret

SECRET=$(openssl rand -hex 64)

echo "JWT_SECRET=$SECRET"
echo ""
echo "Add this to your .env file"
