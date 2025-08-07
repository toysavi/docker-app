#!/bin/sh

# Start backend (Flask app)
python3 /app/backend/app.py &

# Start NGINX (to serve React app)
nginx -g "daemon off;"
