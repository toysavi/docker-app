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
    swarm_info_data = docker_info.get('Swarm', {})
    swarm_status = swarm_info_data.get('LocalNodeState', 'N/A')

    if swarm_status == 'inactive':
        node_type = 'Standalone Node'
        node_role = 'N/A (Not in a Swarm)'
    else:
        node_type = 'Cluster (Swarm Mode)'
        manager_status = swarm_info_data.get('ManagerStatus')
        # A more robust check: first see if it's a manager, then check if it's a leader.
        if manager_status:
            if manager_status.get('Leader'):
                node_role = 'Leader'
            else:
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
