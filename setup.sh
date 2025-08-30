#!/bin/bash
# Development environment setup script

set -e

echo "🚀 Setting up Trading Bot Development Environment..."

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker Compose is available
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo "❌ Docker Compose is not available. Please install Docker Compose first."
    exit 1
fi

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    echo "📝 Creating .env file..."
    cp .env.example .env
    echo "✅ .env file created. Please update it with your configuration."
fi

# Build and start development containers
echo "🐳 Building and starting Docker containers..."
docker-compose -f docker-compose.dev.yml up -d --build

# Wait for database to be ready
echo "⏳ Waiting for database to be ready..."
sleep 10

# Check if containers are running
if docker-compose -f docker-compose.dev.yml ps | grep -q "Up"; then
    echo "✅ Development environment is ready!"
    echo ""
    echo "🔗 Access points:"
    echo "   - API: http://localhost:8000"
    echo "   - API Docs: http://localhost:8000/docs"
    echo "   - PgAdmin: http://localhost:5050 (admin@trading-bot.com/admin)"
    echo "   - Database: localhost:5432 (postgres/password)"
    echo "   - Redis: localhost:6379"
    echo ""
    echo "📚 Next steps:"
    echo "   1. Open the project in VS Code"
    echo "   2. Use 'Dev Containers: Reopen in Container'"
    echo "   3. Start developing your trading strategies!"
else
    echo "❌ Failed to start development environment. Check Docker logs:"
    docker-compose -f docker-compose.dev.yml logs
fi
