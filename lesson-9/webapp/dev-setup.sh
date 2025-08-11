#!/bin/bash

# Development Setup Script for DevOps Demo API
set -e

echo "🚀 DevOps Demo API - Development Setup"
echo "======================================"

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed. Please install Node.js 16+ first."
    exit 1
fi

NODE_VERSION=$(node --version)
echo "✅ Node.js version: $NODE_VERSION"

# Check if npm is installed
if ! command -v npm &> /dev/null; then
    echo "❌ npm is not installed. Please install npm first."
    exit 1
fi

NPM_VERSION=$(npm --version)
echo "✅ npm version: $NPM_VERSION"

# Install dependencies
echo ""
echo "📦 Installing dependencies..."
npm install

# Run tests to verify setup
echo ""
echo "🧪 Running tests to verify setup..."
npm test

# Check if Docker is available
if command -v docker &> /dev/null; then
    echo ""
    echo "🐳 Docker detected. Building container..."
    docker build -t devops-demo-api .
    echo "✅ Docker image built successfully"
    
    echo ""
    echo "🔍 Testing Docker container..."
    # Start container in background
    CONTAINER_ID=$(docker run -d -p 3001:3000 devops-demo-api)
    
    # Wait for container to start
    sleep 3
    
    # Test health endpoint
    if curl -f http://localhost:3001/health > /dev/null 2>&1; then
        echo "✅ Docker container is running and healthy"
    else
        echo "❌ Docker container health check failed"
    fi
    
    # Stop and remove container
    docker stop $CONTAINER_ID > /dev/null
    docker rm $CONTAINER_ID > /dev/null
    
else
    echo ""
    echo "⚠️  Docker not found. Skipping container tests."
fi

echo ""
echo "🎉 Setup complete! You can now:"
echo "   • Start development server: npm run dev"
echo "   • Run tests: npm test"
echo "   • Run specific test types: npm run test:unit, test:functional, etc."
echo "   • Generate coverage: npm run test:coverage"
echo "   • Build Docker image: docker build -t devops-demo-api ."
echo ""
echo "📚 API will be available at: http://localhost:3000"
echo "🏥 Health check: http://localhost:3000/health"
echo "👥 Users API: http://localhost:3000/api/users"
