# Dockerfile for full stack: React frontend + Flask backend (no Docker Compose)

# ----------- Build frontend -----------
FROM node:18 as frontend-builder
WORKDIR /app/frontend
COPY frontend/package*.json ./
RUN npm install
COPY frontend .
RUN npm run build

# ----------- Build backend -----------
FROM python:3.11-slim as backend-builder
WORKDIR /app/backend
COPY backend/app.py ./
RUN pip install flask docker

# ----------- Combine everything -----------
FROM nginx:alpine
# Copy frontend build to nginx
COPY --from=frontend-builder /app/frontend/build /usr/share/nginx/html
# Replace default nginx config
COPY frontend/nginx.conf /etc/nginx/conf.d/default.conf

# Copy backend to /app/backend
COPY --from=backend-builder /app/backend /app/backend
# Add a start script
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Backend runs on port 5000, frontend on 80
EXPOSE 80 5000

CMD ["/start.sh"]
