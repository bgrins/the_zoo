#!/bin/bash
set -e

echo "🚀 Zoo Deployment Container Manager"
echo "===================================="

# Change to the deploy directory
cd "$(dirname "$0")"

CONTAINER_NAME="zoo-deploy"
IMAGE_NAME="zoo-deploy"

# Parse command
case "${1:-help}" in
    build)
        echo "📦 Building deployment image..."
        docker build -t $IMAGE_NAME .
        ;;
    
    run)
        # Stop and remove existing container if it exists
        docker stop $CONTAINER_NAME 2>/dev/null || true
        docker rm $CONTAINER_NAME 2>/dev/null || true
        
        echo "🚀 Starting The Zoo deployment container..."
        echo ""
        docker run -d \
            --name $CONTAINER_NAME \
            --privileged \
            -p 3129:3128 \
            $IMAGE_NAME
        
        echo "Following logs (Ctrl+C to stop)..."
        sleep 2
        docker logs -f $CONTAINER_NAME
        ;;
    
    test)
        echo "🧪 Testing proxy connection..."
        echo ""
        echo "Checking if container is running..."
        if ! docker ps --filter name=$CONTAINER_NAME --filter status=running -q | grep -q .; then
            echo "❌ Container not running. Run './test-deployment.sh run' first"
            exit 1
        fi
        
        echo "Testing proxy at localhost:3129..."
        if curl -s -L -k --proxy http://localhost:3129 http://status.zoo | grep -q "Zoo Status"; then
            echo "✅ Proxy is working! Successfully accessed http://status.zoo"
        else
            echo "❌ Could not access Zoo through proxy"
            echo ""
            echo "Debug info:"
            docker exec $CONTAINER_NAME docker ps --filter name=proxy
        fi
        ;;
    
    stop)
        echo "🛑 Stopping container..."
        docker stop $CONTAINER_NAME || echo "Container not running"
        ;;
    
    logs)
        docker logs ${2:--f} $CONTAINER_NAME
        ;;
    
    shell)
        echo "🐚 Opening shell in container..."
        docker exec -it $CONTAINER_NAME /bin/bash
        ;;
    
    clean)
        echo "🧹 Cleaning up container and volumes..."
        docker stop $CONTAINER_NAME 2>/dev/null || true
        docker rm $CONTAINER_NAME 2>/dev/null || true
        echo "✅ Cleaned up!"
        ;;
    
    *)
        echo "Usage: $0 {build|run|test|stop|logs|shell|clean}"
        echo ""
        echo "  build  - Build the deployment image"
        echo "  run    - Run The Zoo in Docker-in-Docker mode"
        echo "  test   - Test if proxy is working"
        echo "  stop   - Stop the container"
        echo "  logs   - Show container logs"
        echo "  shell  - Open shell in container"
        echo "  clean  - Remove container and volumes"
        echo ""
        echo "Quick start:"
        echo "  $0 build && $0 run"
        echo ""
        echo "Then access Zoo via proxy:"
        echo "  curl -L -k --proxy http://localhost:3129 http://status.zoo"
        ;;
esac