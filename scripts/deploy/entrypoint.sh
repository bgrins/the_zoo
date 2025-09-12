#!/bin/bash
set -e

echo "🦁 Welcome to The Zoo Deployment Container"
echo "==========================================="

# Start Docker daemon in the background (dind mode)
echo "Starting Docker daemon..."
dockerd &> /var/log/dockerd.log &

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
    echo "Docker daemon logs:"
    cat /var/log/dockerd.log
    exit 1
fi

# Check if zoo CLI is installed
if command -v thezoo &> /dev/null; then
    echo "✅ Zoo CLI is installed"
    thezoo --version
else
    echo "⚠️  Zoo CLI not found. Install with: npm install -g the_zoo"
fi

# Parse command line arguments
case "${1:-}" in
    pull)
        echo "📦 Pulling Zoo container images..."
        thezoo pull
        ;;
    start)
        echo "🚀 Starting Zoo environment..."
        thezoo start
        ;;
    stop)
        echo "🛑 Stopping Zoo environment..."
        thezoo stop
        ;;
    status)
        thezoo status
        ;;
    init)
        echo "🚀 Initializing Zoo environment..."
        echo "Creating default instance and pulling images..."
        thezoo create
        thezoo pull
        echo "✅ Zoo environment initialized. Run 'start' to begin."
        ;;
    *)
        echo ""
        echo "Available commands:"
        echo "  init   - Initialize Zoo environment (create instance & pull images)"
        echo "  start  - Start Zoo services"
        echo "  stop   - Stop Zoo services"
        echo "  status - Show status of Zoo services"
        echo "  pull   - Pull all Zoo container images"
        echo "  bash   - Start interactive shell (default)"
        echo ""
        echo "Or use 'thezoo' directly for full CLI access"
        echo ""
        exec "$@"
        ;;
esac