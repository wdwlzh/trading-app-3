.PHONY: help build up down logs shell test lint format clean

# Default target
help:
	@echo "Trading Bot Development Commands:"
	@echo ""
	@echo "Setup (run once):"
	@echo "  make setup     - Initial setup and instructions"
	@echo ""
	@echo "Dev Container Commands (use these inside VS Code dev container):"
	@echo "  make test      - Run tests"
	@echo "  make lint      - Run linting"
	@echo "  make format    - Format code with Black"
	@echo "  make jupyter   - Start Jupyter Lab"
	@echo ""
	@echo "Docker Commands (use these outside container):"
	@echo "  make docker-up    - Start services manually"
	@echo "  make docker-down  - Stop services"
	@echo "  make docker-logs  - View container logs"
	@echo "  make docker-clean - Clean up containers and volumes"

setup:
	@chmod +x setup.sh
	@./setup.sh

# Commands for inside dev container
test:
	@if [ -f /.dockerenv ]; then 
		pytest tests/ -v; 
	else 
		echo "❌ Run this command inside the dev container (VS Code: Reopen in Container)"; 
	fi

lint:
	@if [ -f /.dockerenv ]; then 
		pylint src/; 
	else 
		echo "❌ Run this command inside the dev container (VS Code: Reopen in Container)"; 
	fi

format:
	@if [ -f /.dockerenv ]; then 
		black src/ tests/; 
	else 
		echo "❌ Run this command inside the dev container (VS Code: Reopen in Container)"; 
	fi

jupyter:
	@if [ -f /.dockerenv ]; then 
		jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root; 
	else 
		echo "❌ Run this command inside the dev container (VS Code: Reopen in Container)"; 
	fi

# Docker commands for outside container
docker-up:
	@docker-compose -f docker-compose.dev.yml up -d
	@echo "✅ Services started!"
	@echo "🔗 Access points:"
	@echo "   - API: http://localhost:8000"
	@echo "   - PgAdmin: http://localhost:5050"

docker-down:
	@docker-compose -f docker-compose.dev.yml down

docker-logs:
	@docker-compose -f docker-compose.dev.yml logs -f

docker-clean:
	@docker-compose -f docker-compose.dev.yml down -v --remove-orphans
	@docker system prune -f

# Legacy aliases (deprecated)
up: docker-up
down: docker-down
logs: docker-logs
clean: docker-clean

setup:
	@chmod +x setup.sh
	@./setup.sh

build:
	@docker-compose -f docker-compose.dev.yml build

up:
	@docker-compose -f docker-compose.dev.yml up -d
	@echo "Development environment started!"
	@echo "API: http://localhost:8000"
	@echo "Docs: http://localhost:8000/docs"

down:
	@docker-compose -f docker-compose.dev.yml down

logs:
	@docker-compose -f docker-compose.dev.yml logs -f

shell:
	@docker-compose -f docker-compose.dev.yml exec app bash

test:
	@docker-compose -f docker-compose.dev.yml exec app pytest tests/ -v

lint:
	@docker-compose -f docker-compose.dev.yml exec app pylint src/

format:
	@docker-compose -f docker-compose.dev.yml exec app black src/ tests/

clean:
	@docker-compose -f docker-compose.dev.yml down -v --remove-orphans
	@docker system prune -f

db-shell:
	@docker-compose -f docker-compose.dev.yml exec db psql -U postgres trading_bot

# Jupyter notebook
jupyter:
	@docker-compose -f docker-compose.dev.yml exec app jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root

# Install new package
install:
	@read -p "Package name: " pkg; \
	docker-compose -f docker-compose.dev.yml exec app pip install $$pkg; \
	docker-compose -f docker-compose.dev.yml exec app pip freeze > requirements.txt
