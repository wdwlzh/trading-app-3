# Trading Bot Application

A comprehensive trading bot application with Interactive Brokers integration, backtesting capabilities, and performance analysis.

## Features

- 🔗 Interactive Brokers Gateway integration
- 📊 Real-time market data processing
- 🧠 Customizable trading strategies
- 📈 Comprehensive backtesting engine
- 📊 Performance analytics and reporting
- 🐳 Docker containerized development environment
- 🗄️ TimescaleDB for time-series data
- ⚡ FastAPI REST API
- 📝 Jupyter notebook support for analysis

## Quick Start

### Prerequisites

- Docker and Docker Compose
- VS Code with Dev Containers extension
- Interactive Brokers TWS or IB Gateway (for live trading)

### Development Setup

1. **Clone the repository**
   ```bash
   git clone <your-repo-url>
   cd trading-app-3
   ```

2. **Initial setup**
   ```bash
   ./setup.sh
   # or
   make setup
   ```

3. **Open in VS Code Dev Container** (Recommended)
   ```bash
   code .
   ```
   - When prompted, click **"Reopen in Container"**
   - Or use Command Palette: `Dev Containers: Reopen in Container`
   - This will automatically start Docker Desktop and set up everything

4. **Alternative: Manual Docker setup** (if not using dev container)
   ```bash
   make docker-up
   ```

5. **Verify setup**
   - API: http://localhost:8000
   - Database: localhost:5432 (postgres/password)
   - PgAdmin: http://localhost:5050 (admin@trading-bot.com/admin)
   - Redis: localhost:6379

### Development Workflow

**Inside Dev Container (VS Code):**
```bash
make test      # Run tests
make lint      # Run linting
make format    # Format code
make jupyter   # Start Jupyter Lab
```

**Outside Container:**
```bash
make docker-up     # Start services
make docker-down   # Stop services  
make docker-logs   # View logs
make docker-clean  # Clean up
```

### Project Structure

```
trading-bot/
├── src/                    # Source code
│   ├── api/               # REST API endpoints
│   ├── brokers/           # IB Gateway integration
│   ├── data/              # Data management
│   ├── strategies/        # Trading algorithms
│   ├── backtesting/       # Backtesting engine
│   ├── portfolio/         # Account & portfolio management
│   ├── analytics/         # Performance analysis
│   └── utils/             # Shared utilities
├── tests/                 # Test files
├── docker/               # Docker configurations
├── .devcontainer/        # VS Code dev container config
├── migrations/           # Database migrations
└── config/               # Configuration files
```

## Development Workflow

1. **Write your strategy** in `src/strategies/`
2. **Test with backtesting** using historical data
3. **Paper trade** to validate in real-time
4. **Deploy** when satisfied with performance

## Configuration

Copy `.env.example` to `.env` and update the configuration:

```bash
cp .env.example .env
```

Key configuration options:
- `DATABASE_URL`: PostgreSQL connection string
- `IB_HOST/IB_PORT`: Interactive Brokers connection details
- `REDIS_URL`: Redis connection for caching

## Interactive Brokers Setup

1. Download and install IB Gateway or TWS
2. Configure paper trading account
3. Enable API connections in settings
4. Update `IB_HOST` and `IB_PORT` in `.env`

## Running Tests

```bash
pytest tests/ -v
```

## API Documentation

Once the application is running, visit:
- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

## Database Management

Access the database:
```bash
# Via PgAdmin: http://localhost:5050
# Via psql:
docker exec -it trading-app-3_db_1 psql -U postgres trading_bot
```

## Jupyter Notebooks

Start Jupyter for analysis:
```bash
jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root
```

## License

MIT License - see LICENSE file for details

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## Support

For questions or issues, please open an issue on GitHub.
