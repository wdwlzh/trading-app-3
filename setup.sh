#!/bin/bash
# Development environment setup script

set -e

echo "🚀 Setting up Trading Bot Development Environment..."

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    echo "📝 Creating .env file..."
    cp .env.example .env
    echo "✅ .env file created. Please update it with your configuration."
else
    echo "✅ .env file already exists."
fi

# Create data directory for backtesting
mkdir -p data

echo ""
echo "✅ Basic setup complete!"
echo ""
echo "🔄 Next steps:"
echo "   1. Open VS Code: code ."
echo "   2. When prompted, click 'Reopen in Container'"
echo "   3. Or use Command Palette: 'Dev Containers: Reopen in Container'"
echo ""
echo "� The dev container will automatically:"
echo "   - Start Docker Desktop if needed"
echo "   - Build and start all services (database, redis, etc.)"
echo "   - Install Python dependencies"
echo "   - Set up the development environment"
echo ""
echo "🔗 Once running, access points will be:"
echo "   - API: http://localhost:8000"
echo "   - API Docs: http://localhost:8000/docs"
echo "   - PgAdmin: http://localhost:5050 (admin@trading-bot.com/admin)"
echo "   - Database: localhost:5432 (postgres/password)"
