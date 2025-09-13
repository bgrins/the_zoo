#!/bin/bash
set -e

echo "🦁 Welcome to The Zoo Deployment Container"
echo "==========================================="

# Check if we have privileges to run dockerd
if [ ! -w /sys/fs/cgroup ]; then
    echo "❌ Cannot start Docker daemon without --privileged flag"
    echo ""
    echo "Please run with: docker run --privileged zoo-deploy"
    exit 1
fi

# Start Docker daemon in the background
echo "Starting Docker daemon..."
dockerd > /var/log/dockerd.log 2>&1 &

# Wait for Docker to be ready
echo "Waiting for Docker to be ready..."
for i in {1..30}; do
    if docker info >/dev/null 2>&1; then
        echo "✅ Docker daemon is ready"
        break
    fi
    sleep 1
done

# Check if Docker is actually working
if ! docker info >/dev/null 2>&1; then
    echo "❌ Docker daemon failed to start"
    cat /var/log/dockerd.log
    exit 1
fi

# Start The Zoo
echo ""
echo "🚀 Starting The Zoo..."
echo ""

# The Zoo CLI will automatically bind the proxy to 0.0.0.0:3128
the_zoo create || true
the_zoo start

# Wait for proxy container to be running
echo ""
echo "Waiting for proxy container to start..."
for i in {1..30}; do
    if docker ps --filter name=proxy --filter status=running -q 2>/dev/null | grep -q .; then
        echo "✅ Proxy container is running and ready"
        docker ps --filter name=proxy --format "  {{.Names}}: {{.Ports}}"
        break
    fi
    sleep 1
done

# Test the proxy
echo ""
echo "Testing proxy connection..."
if curl -s -L --proxy http://localhost:3128 http://status.zoo -o /dev/null -w "%{http_code}" 2>/dev/null | grep -q "200"; then
    echo "✅ Proxy is working!"
else
    echo "⚠️  Proxy may need a moment to initialize"
fi

# Show final status
echo ""
echo "✅ The Zoo is running!"
echo ""
echo "From host machine, access via:"
echo "  curl -L -k --proxy http://localhost:3129 http://status.zoo"
echo ""
echo "Or configure your browser to use proxy: localhost:3129"
echo ""

# Keep the container alive
tail -f /dev/null