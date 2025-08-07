## 📁 Project Structure for Single-Image Fullstack Docker App

```
sample-docker-app/
├── backend/
│   └── app.py
├── frontend/
│   ├── src/
│   │   └── App.jsx
│   ├── public/
│   │   └── index.html
│   ├── package.json
│   └── nginx.conf
├── start.sh
├── Dockerfile
└── README.md
```

### 🔧 Explanation

- `backend/app.py` - Flask backend using Docker SDK to detect Docker info.
- `frontend/src/App.jsx` - React frontend UI.
- `frontend/public/index.html` - React entry HTML.
- `frontend/package.json` - React dependencies and scripts.
- `frontend/nginx.conf` - Configures NGINX to serve React app and proxy `/api` to Flask backend.
- `start.sh` - Shell script to launch both backend and NGINX in one container.
- `Dockerfile` - Unified Dockerfile that builds everything into one container image.

### 🚀 How to Build & Run (without Docker Compose)

```bash
# Step 1: Make sure start.sh is executable
chmod +x start.sh

# Step 2: Build the image
docker build -t sample-docker-app .

# Step 3: Run the container (with Docker socket mounted)
docker run -p 80:80 -p 5000:5000 -v /var/run/docker.sock:/var/run/docker.sock sample-docker-app
```

### 🌐 Access:
- Frontend: http://localhost
- Backend API: http://localhost/api/docker-info
