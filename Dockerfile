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
