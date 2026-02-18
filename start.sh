#!/usr/bin/env bash
# Local Development Startup Script
set -euo pipefail

echo "🚀 Starting Trading Workstation (Development Mode)"
echo "=================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker is not installed${NC}"
    echo "Please install Docker Desktop from: https://www.docker.com/products/docker-desktop"
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}❌ Docker Compose is not installed${NC}"
    echo "Please install Docker Compose from: https://docs.docker.com/compose/install/"
    exit 1
fi

echo -e "${GREEN}✓ Docker is installed${NC}"
echo -e "${GREEN}✓ Docker Compose is installed${NC}"

# Check if .env file exists
if [ ! -f .env ]; then
    echo -e "${YELLOW}⚠ No .env file found${NC}"
    echo "Creating .env from template..."
    cp .env.template .env
    echo -e "${GREEN}✓ Created .env file${NC}"
    echo -e "${YELLOW}⚠ Please edit .env file with your configuration before continuing${NC}"
    echo "Opening .env in default editor..."
    
    # Try to open .env in editor
    if command -v nano &> /dev/null; then
        nano .env
    elif command -v vim &> /dev/null; then
        vim .env
    else
        echo "Please edit .env manually with your preferred editor"
        exit 0
    fi
fi

echo ""
echo "📦 Building and starting services..."
echo "This may take a few minutes on first run..."
echo ""

# Build and start services
docker-compose up --build -d

# Wait for services to be ready
echo ""
echo "⏳ Waiting for services to be ready..."
sleep 5

# Check if services are running
if docker-compose ps | grep -q "Up"; then
    echo -e "${GREEN}✓ Services are running!${NC}"
else
    echo -e "${RED}❌ Some services failed to start${NC}"
    echo "Checking logs..."
    docker-compose logs --tail=50
    exit 1
fi

# Show service status
echo ""
echo "📊 Service Status:"
docker-compose ps

echo ""
echo "=================================================="
echo -e "${GREEN}🎉 Trading Workstation is running!${NC}"
echo "=================================================="
echo ""
echo "📱 Access your dashboard at:"
echo "   http://localhost:8000"
echo ""
echo "🔍 View logs:"
echo "   docker-compose logs -f"
echo ""
echo "🛑 Stop services:"
echo "   docker-compose down"
echo ""
echo "🔄 Restart services:"
echo "   docker-compose restart"
echo ""
echo "💾 Database Management:"
echo "   - PostgreSQL: localhost:5432"
echo "   - Redis: localhost:6379"
echo ""
echo "=================================================="

# Open browser (optional)
read -p "Open browser now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if command -v xdg-open &> /dev/null; then
        xdg-open http://localhost:8000
    elif command -v open &> /dev/null; then
        open http://localhost:8000
    else
        echo "Please open http://localhost:8000 in your browser"
    fi
fi
