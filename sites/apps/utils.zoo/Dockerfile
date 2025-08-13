FROM python:3.11-slim

# Install curl for health checks
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy requirements first for better caching
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Expose port
EXPOSE 3000

# Run the application with auto-reload for development
CMD ["python", "-m", "flask", "run", "--host=0.0.0.0", "--port=3000", "--reload"]
