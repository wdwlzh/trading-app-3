.PHONY: help build up down logs shell test lint format clean

# Default target
help:
	@echo "Trading Bot Development Commands:"
	@echo "  make setup     - Initial setup (run once)"
	@echo "  make build     - Build Docker containers"
	@echo "  make up        - Start development environment"
	@echo "  make down      - Stop development environment"
	@echo "  make logs      - View container logs"
	@echo "  make shell     - Access development container shell"
	@echo "  make test      - Run tests"
	@echo "  make lint      - Run linting"
	@echo "  make format    - Format code with Black"
	@echo "  make clean     - Clean up containers and volumes"
	@echo "  make db-shell  - Access database shell"

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
