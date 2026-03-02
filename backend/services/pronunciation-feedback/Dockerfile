# Base image: official Python 3.12 slim (Debian-based, smaller than full python image).
FROM python:3.12-slim

# Set working directory inside the container; all following paths are relative to this.
WORKDIR /app

# Copy only the dependency list first so that layer can be cached when code changes.
# This speeds up rebuilds when only application code (not requirements) changes.
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application into the container.
# .dockerignore excludes __pycache__, .env, venv, etc., so they are not copied.
COPY . .

# Document that the container listens on port 8000 (informational; does not publish the port).
# The actual mapping is done by docker run -p or docker-compose ports.
EXPOSE 8000

# Start the FastAPI app with uvicorn. Binding to 0.0.0.0 allows external connections
# to reach the server (default 127.0.0.1 would only accept connections from inside the container).
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
