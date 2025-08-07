from flask import Flask, jsonify
import docker
import socket

app = Flask(__name__)
client = docker.from_env()

@app.route("/api/docker-info")
def docker_info():
    try:
        info = client.info()
        mode = "Swarm Mode" if info.get("Swarm", {}).get("LocalNodeState") == "active" else "Standalone Node"
        node_name = info.get("Name", "Unknown")
        node_ip = socket.gethostbyname(socket.gethostname())

        containers = []
        for c in client.containers.list():
            networks = c.attrs['NetworkSettings']['Networks']
            ip = next(iter(networks.values()))['IPAddress']
            containers.append({"name": c.name, "ip": ip})

        return jsonify({
            "mode": mode,
            "nodeName": node_name,
            "nodeIP": node_ip,
            "containers": containers
        })

    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(host="0.0.0.0", port=5000)
