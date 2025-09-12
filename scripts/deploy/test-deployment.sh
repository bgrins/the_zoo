#!/bin/bash
set -e

echo "🚀 Testing Zoo Deployment Container"
echo "===================================="

# Change to the deploy directory
cd "$(dirname "$0")"

# Build the deployment image
echo ""
echo "📦 Building deployment image..."
docker build -t zoo-deploy .

# Test 1: Check if the CLI is installed (no Docker needed)
echo ""
echo "✅ Test 1: Checking CLI installation..."
docker run --rm zoo-deploy thezoo --version

# Test 2: Test pull command (Docker-in-Docker mode)
echo ""
echo "✅ Test 2: Testing pull command..."
echo "This will pull Zoo images inside the container..."
docker run --rm --privileged zoo-deploy pull

# Test 3: Test init command (create instance and pull)
echo ""
echo "✅ Test 3: Testing init command..."
docker run --rm --privileged zoo-deploy init

# Test 4: Test status command
echo ""
echo "✅ Test 4: Testing status command..."
docker run --rm --privileged zoo-deploy status

# Test 5: Interactive shell
echo ""
echo "✅ Test 5: Starting interactive shell (Docker-in-Docker mode)..."
echo "You can test commands like:"
echo "  - thezoo status"
echo "  - thezoo pull"
echo "  - thezoo start"
echo "  - thezoo stop"
echo ""
echo "Note: This runs in isolated Docker-in-Docker mode"
echo "Images and containers are separate from your host Docker"
echo ""
docker run -it --rm --privileged zoo-deploy bash

echo ""
echo "🎉 All tests completed!"