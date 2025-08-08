#!/bin/bash
# This script creates all the necessary files for the Docker web application.

# Exit immediately if a command exits with a non-zero status.
set -e

echo "Creating directory structure..."
mkdir -p templates
echo "Directory 'templates' created."
echo ""

# 1. Create the Dockerfile
cat <<'EOF' > Dockerfile
#
# --- Dockerfile ---
# This file is used to build the Docker image.
#
# A Python 3.10 base image is a good choice for running a Flask app.
FROM python:3.10-alpine

# Set the working directory inside the container.
WORKDIR /app

# Install cURL, jq, and bash.
RUN apk add --no-cache curl jq bash

# Copy the requirements file and install the Python dependencies.
COPY requirements.txt requirements.txt
RUN pip install -r requirements.txt

# Copy the application files into the container.
COPY . .

# Expose port 5000, which is the default port for the Flask development server.
EXPOSE 5000

# The CMD instruction passes the entrypoint script to the bash interpreter.
# This is a robust way to avoid line-ending issues on the script itself.
CMD ["/bin/bash", "entrypoint.sh"]
EOF

echo "Created Dockerfile."
echo "--------------------"

# 2. Create the requirements.txt file
cat <<'EOF' > requirements.txt
#
# --- requirements.txt ---
# This file lists the Python packages needed for our web app.
#
Flask
EOF

echo "Created requirements.txt."
echo "--------------------"

# 3. Create the entrypoint.sh script
cat <<'EOF' > entrypoint.sh
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
EOF

# Note: We no longer need to make this executable since we call it with bash.
# chmod +x entrypoint.sh

echo "Created entrypoint.sh."
echo "--------------------"

# 4. Create the app.py file
cat <<'EOF' > app.py
#
# --- app.py ---
# This is the Python Flask application that serves the web page.
#
from flask import Flask, render_template
import subprocess
import json

app = Flask(__name__)

# Function to execute a shell command and return its output.
def run_command(command):
    try:
        result = subprocess.run(command, shell=True, capture_output=True, text=True, check=True)
        return result.stdout.strip()
    except subprocess.CalledProcessError as e:
        print(f"Error executing command: {e.cmd}")
        print(f"Stderr: {e.stderr}")
        return None

# The main route for the web application.
@app.route('/')
def index():
    # --- 1. Get Docker Host Info ---
    # Use the Docker socket to get host information.
    docker_info_json = run_command('curl --silent --unix-socket /var/run/docker.sock http://localhost/info')
    docker_info = json.loads(docker_info_json)
    host_name = docker_info.get('Name', 'N/A')
    docker_version = docker_info.get('ServerVersion', 'N/A')
    host_os = docker_info.get('OperatingSystem', 'N/A')
    
    # Get the host's IP address.
    host_ip = run_command("ip route | awk '/default/ {print $3}'") or 'N/A'

    # --- 2. Get Container Info ---
    # A more robust way to get the container ID is to use the hostname.
    container_id_full = run_command("hostname")
    if not container_id_full:
        container_info = {
            'name': 'N/A',
            'id': 'N/A',
            'ip': 'N/A',
            'network': 'N/A'
        }
    else:
        container_info_json = run_command(f'curl --silent --unix-socket /var/run/docker.sock http://localhost/containers/{container_id_full}/json')
        container_data = json.loads(container_info_json)
        container_name = container_data.get('Name', 'N/A').lstrip('/')
        container_id_short = container_data.get('Id', 'N/A')[:12]
        
        # Get network details.
        networks = container_data.get('NetworkSettings', {}).get('Networks', {})
        network_name = list(networks.keys())[0] if networks else 'N/A'
        container_ip = networks.get(network_name, {}).get('IPAddress', 'N/A')
        
        container_info = {
            'name': container_name,
            'id': container_id_short,
            'ip': container_ip,
            'network': network_name
        }

    # --- 3. Get Swarm Info ---
    swarm_status = docker_info.get('Swarm', {}).get('LocalNodeState', 'N/A')
    if swarm_status == 'inactive':
        node_type = 'Standalone Node'
        node_role = 'N/A (Not in a Swarm)'
    else:
        node_type = 'Cluster (Swarm Mode)'
        # Check if the node is a manager to provide a more specific role.
        if docker_info.get('Swarm', {}).get('ManagerStatus'):
            node_role = 'Manager'
        elif swarm_status == 'active':
            node_role = 'Worker'
        else:
            node_role = f'Unknown ({swarm_status})'

    swarm_info = {
        'node_type': node_type,
        'node_role': node_role
    }

    # Render the HTML template with the collected data.
    return render_template(
        'index.html',
        host_name=host_name,
        host_ip=host_ip,
        docker_version=docker_version,
        host_os=host_os,
        container_info=container_info,
        swarm_info=swarm_info
    )

# Run the Flask app.
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
EOF

echo "Created app.py."
echo "--------------------"

# 5. Create the templates/index.html file
cat <<'EOF' > templates/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Docker Host Info</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700&display=swap');
        body {
            font-family: 'Inter', sans-serif;
        }
        /* Custom CSS for a subtle hover effect */
        .card-item {
            transition: transform 0.2s ease-in-out, box-shadow 0.2s ease-in-out;
        }
        .card-item:hover {
            transform: translateY(-4px);
            box-shadow: 10px 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05);
        }
    </style>
</head>
<body class="bg-gray-50 text-gray-900 flex items-center justify-center min-h-screen p-6">
    <div class="bg-white rounded-2xl shadow-xl p-8 w-full max-w-3xl mx-auto border border-gray-100">
        <h1 class="text-4xl font-bold mb-8 text-center text-gray-800 tracking-tight">Docker Environment</h1>
        
        <div class="space-y-8">
            <!-- Docker Host Info Section -->
            <div class="card-item bg-blue-50 p-6 rounded-xl border border-blue-100 transform hover:scale-105 transition-all duration-300 ease-in-out">
                <h2 class="text-xl font-semibold text-blue-800 mb-4 flex items-center">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 mr-2 text-blue-500" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M9.75 17L9.25 10H13.75L14.25 17H9.75Z" />
                        <path stroke-linecap="round" stroke-linejoin="round" d="M12 21a9 9 0 100-18 9 9 0 000 18z" />
                    </svg>
                    Docker Host
                </h2>
                <div class="grid grid-cols-1 md:grid-cols-2 gap-y-4 gap-x-8 text-sm">
                    <p class="font-medium text-gray-700">Host Name: <span class="block font-normal text-gray-600 break-words">{{ host_name }}</span></p>
                    <p class="font-medium text-gray-700">Host IP: <span class="block font-normal text-gray-600 break-words">{{ host_ip }}</span></p>
                    <p class="font-medium text-gray-700">Docker Version: <span class="block font-normal text-gray-600 break-words">{{ docker_version }}</span></p>
                    <p class="font-medium text-gray-700">Host OS: <span class="block font-normal text-gray-600 break-words">{{ host_os }}</span></p>
                </div>
            </div>

            <!-- Current Container Info Section -->
            <div class="card-item bg-green-50 p-6 rounded-xl border border-green-100 transform hover:scale-105 transition-all duration-300 ease-in-out">
                <h2 class="text-xl font-semibold text-green-800 mb-4 flex items-center">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 mr-2 text-green-500" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                        <path stroke-linecap="round" stroke-linejoin="round" d="M10 12h2a2 2 0 012 2v2a2 2 0 01-2 2h-2v-4z" />
                    </svg>
                    Current Container
                </h2>
                <div class="grid grid-cols-1 md:grid-cols-2 gap-y-4 gap-x-8 text-sm">
                    <p class="font-medium text-gray-700">Container Name: <span class="block font-normal text-gray-600 break-words">{{ container_info.name }}</span></p>
                    <p class="font-medium text-gray-700">Container ID: <span class="block font-normal text-gray-600 break-words">{{ container_info.id }}</span></p>
                    <p class="font-medium text-gray-700">Container IP: <span class="block font-normal text-gray-600 break-words">{{ container_info.ip }}</span></p>
                    <p class="font-medium text-gray-700">Container Network: <span class="block font-normal text-gray-600 break-words">{{ container_info.network }}</span></p>
                </div>
            </div>

            <!-- Docker Swarm Info Section -->
            <div class="card-item bg-yellow-50 p-6 rounded-xl border border-yellow-100 transform hover:scale-105 transition-all duration-300 ease-in-out">
                <h2 class="text-xl font-semibold text-yellow-800 mb-4 flex items-center">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 mr-2 text-yellow-500" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M13 10V3L4 14H11V21L20 10H13Z" />
                    </svg>
                    Docker Swarm
                </h2>
                <div class="grid grid-cols-1 md:grid-cols-2 gap-y-4 gap-x-8 text-sm">
                    <p class="font-medium text-gray-700">Docker Node: <span class="block font-normal text-gray-600 break-words">{{ swarm_info.node_type }}</span></p>
                    <p class="font-medium text-gray-700">Node Role: <span class="block font-normal text-gray-600 break-words">{{ swarm_info.node_role }}</span></p>
                </div>
            </div>
        </div>

        <footer class="mt-8 text-center text-sm text-gray-500 pt-4 border-t border-gray-200">
            &copy; 2023 Docker Info App. All rights reserved.
        </footer>
    </div>
</body>
</html>
EOF

echo "Created templates/index.html."
echo "--------------------"

echo "All necessary files have been created successfully!"
echo "Now you can run 'docker build -t my-docker-info-web-app .'"
echo "and then 'docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -p 5000:5000 my-docker-info-web-app' to start the application."
