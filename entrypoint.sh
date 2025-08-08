#
# --- entrypoint.sh ---
# This script starts the Flask web application.
#
#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# The Docker socket MUST be mounted for this script to work.
if [ ! -S /var/run/docker.sock ]; then
    echo "Error: Docker socket /var/run/docker.sock is not mounted."
    echo "Please run the container with: docker run -v /var/run/docker.sock:/var/run/docker.sock -p 5000:5000 <image_name>"
    exit 1
fi

# Start the Flask web server.
# It listens on all network interfaces (0.0.0.0) on port 5000.
exec python3 app.py
