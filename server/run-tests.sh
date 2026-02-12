#!/bin/bash
echo "🧪 Todo Sync Server - Quick Test Runner"
echo "========================================"
echo ""
echo "Starting server and opening test UI..."
echo ""

# Start server in background
npm start &
SERVER_PID=$!

# Wait for server to start
sleep 3

# Open browser (works on most Linux with X11)
if command -v xdg-open &> /dev/null; then
    xdg-open "https://localhost:8443/tests.html"
elif command -v gnome-open &> /dev/null; then
    gnome-open "https://localhost:8443/tests.html"
else
    echo "✅ Server started!"
    echo "📱 Open in browser: https://localhost:8443/tests.html"
fi

echo ""
echo "Press Ctrl+C to stop server"
echo ""

# Wait for interrupt
trap "kill $SERVER_PID; exit" INT
wait $SERVER_PID
