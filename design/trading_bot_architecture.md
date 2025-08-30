# Trading Bot Application Architecture & Development Plan

## System Overview
A comprehensive trading bot application with Interactive Brokers integration, backtesting capabilities, and performance analysis.

## Architecture Components

### 1. Core Application Structure
```
trading-bot/
├── src/
│   ├── api/                    # REST API endpoints
│   ├── brokers/               # IB Gateway integration
│   ├── data/                  # Data management
│   ├── strategies/            # Trading algorithms
│   ├── backtesting/          # Backtesting engine
│   ├── portfolio/            # Account & portfolio management
│   ├── analytics/            # Performance analysis
│   └── utils/                # Shared utilities
├── tests/
├── docker/
├── .devcontainer/
├── migrations/
└── config/
```

### 2. Technology Stack
- **Backend**: Python 3.11+ with FastAPI
- **Database**: PostgreSQL with TimescaleDB extension for time-series data
- **Message Queue**: Redis for real-time data processing
- **Containerization**: Docker & Docker Compose
- **Development**: VS Code with Dev Containers
- **Deployment**: Digital Ocean Droplet with Docker
- **IB Integration**: ib_insync library

### 3. Database Schema Design

#### Market Data Tables
```sql
-- Symbols configuration
CREATE TABLE symbols (
    id SERIAL PRIMARY KEY,
    symbol VARCHAR(20) NOT NULL UNIQUE,
    exchange VARCHAR(10),
    currency VARCHAR(3),
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Real-time price data (TimescaleDB hypertable)
CREATE TABLE price_data (
    time TIMESTAMPTZ NOT NULL,
    symbol_id INTEGER REFERENCES symbols(id),
    open DECIMAL(12,4),
    high DECIMAL(12,4),
    low DECIMAL(12,4),
    close DECIMAL(12,4),
    volume BIGINT,
    PRIMARY KEY (time, symbol_id)
);

-- Historical data for backtesting
CREATE TABLE historical_data (
    time TIMESTAMPTZ NOT NULL,
    symbol_id INTEGER REFERENCES symbols(id),
    timeframe VARCHAR(5), -- '1min', '5min', '1hour', '1day'
    open DECIMAL(12,4),
    high DECIMAL(12,4),
    low DECIMAL(12,4),
    close DECIMAL(12,4),
    volume BIGINT,
    PRIMARY KEY (time, symbol_id, timeframe)
);
```

#### Portfolio & Account Management
```sql
-- Account information
CREATE TABLE accounts (
    id SERIAL PRIMARY KEY,
    account_id VARCHAR(50) UNIQUE,
    broker VARCHAR(20) DEFAULT 'IB',
    total_cash DECIMAL(15,2),
    available_funds DECIMAL(15,2),
    buying_power DECIMAL(15,2),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Positions tracking
CREATE TABLE positions (
    id SERIAL PRIMARY KEY,
    account_id INTEGER REFERENCES accounts(id),
    symbol_id INTEGER REFERENCES symbols(id),
    quantity DECIMAL(12,4),
    avg_cost DECIMAL(12,4),
    market_value DECIMAL(15,2),
    unrealized_pnl DECIMAL(15,2),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Trade execution history
CREATE TABLE trades (
    id SERIAL PRIMARY KEY,
    account_id INTEGER REFERENCES accounts(id),
    symbol_id INTEGER REFERENCES symbols(id),
    order_id VARCHAR(50),
    side VARCHAR(4) CHECK (side IN ('BUY', 'SELL')),
    quantity DECIMAL(12,4),
    price DECIMAL(12,4),
    commission DECIMAL(8,2),
    executed_at TIMESTAMP,
    strategy_name VARCHAR(50)
);
```

#### Backtesting & Strategy Management
```sql
-- Strategy definitions
CREATE TABLE strategies (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE,
    description TEXT,
    parameters JSONB,
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Backtesting runs
CREATE TABLE backtest_runs (
    id SERIAL PRIMARY KEY,
    strategy_id INTEGER REFERENCES strategies(id),
    start_date DATE,
    end_date DATE,
    initial_capital DECIMAL(15,2),
    symbols TEXT[], -- Array of symbols
    parameters JSONB,
    status VARCHAR(20) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT NOW(),
    completed_at TIMESTAMP
);

-- Backtesting results
CREATE TABLE backtest_results (
    id SERIAL PRIMARY KEY,
    run_id INTEGER REFERENCES backtest_runs(id),
    total_return DECIMAL(8,4),
    sharpe_ratio DECIMAL(8,4),
    max_drawdown DECIMAL(8,4),
    win_rate DECIMAL(8,4),
    total_trades INTEGER,
    profit_factor DECIMAL(8,4),
    results_data JSONB -- Detailed results
);
```

### 4. Development Environment Setup

#### .devcontainer/devcontainer.json
```json
{
    "name": "Trading Bot Dev Environment",
    "dockerComposeFile": "../docker-compose.dev.yml",
    "service": "app",
    "workspaceFolder": "/workspace",
    "features": {
        "ghcr.io/devcontainers/features/python:1": {
            "version": "3.11"
        }
    },
    "customizations": {
        "vscode": {
            "extensions": [
                "ms-python.python",
                "ms-python.pylint",
                "ms-python.black-formatter",
                "ms-toolsai.jupyter",
                "cweijan.vscode-postgresql-client2"
            ],
            "settings": {
                "python.defaultInterpreterPath": "/usr/local/bin/python",
                "python.formatting.provider": "black"
            }
        }
    },
    "postCreateCommand": "pip install -r requirements.txt",
    "remoteUser": "vscode"
}
```

### 5. Core Application Components

#### Interactive Brokers Integration
```python
# src/brokers/ib_client.py
from ib_insync import IB, Stock, Order
import asyncio
from typing import List, Dict

class IBClient:
    def __init__(self, host='127.0.0.1', port=7497, client_id=1):
        self.ib = IB()
        self.host = host
        self.port = port
        self.client_id = client_id
        
    async def connect(self):
        await self.ib.connectAsync(self.host, self.port, self.client_id)
        
    async def get_account_info(self):
        account_values = self.ib.accountValues()
        return {av.tag: av.value for av in account_values}
        
    async def get_positions(self):
        return self.ib.positions()
        
    async def place_order(self, symbol: str, quantity: int, order_type: str = 'MKT'):
        stock = Stock(symbol, 'SMART', 'USD')
        order = Order()
        order.action = 'BUY' if quantity > 0 else 'SELL'
        order.totalQuantity = abs(quantity)
        order.orderType = order_type
        
        trade = self.ib.placeOrder(stock, order)
        return trade
```

#### Data Management Service
```python
# src/data/data_manager.py
import asyncio
import asyncpg
from datetime import datetime, timedelta
import pandas as pd

class DataManager:
    def __init__(self, db_url: str):
        self.db_url = db_url
        self.pool = None
        
    async def init_pool(self):
        self.pool = await asyncpg.create_pool(self.db_url)
        
    async def store_price_data(self, symbol: str, data: Dict):
        async with self.pool.acquire() as conn:
            await conn.execute(
                """INSERT INTO price_data 
                   (time, symbol_id, open, high, low, close, volume)
                   VALUES ($1, (SELECT id FROM symbols WHERE symbol = $2), 
                          $3, $4, $5, $6, $7)""",
                data['timestamp'], symbol, data['open'], 
                data['high'], data['low'], data['close'], data['volume']
            )
            
    async def get_historical_data(self, symbol: str, start_date: datetime, 
                                 end_date: datetime) -> pd.DataFrame:
        async with self.pool.acquire() as conn:
            rows = await conn.fetch(
                """SELECT time, open, high, low, close, volume 
                   FROM historical_data hd
                   JOIN symbols s ON hd.symbol_id = s.id
                   WHERE s.symbol = $1 AND time BETWEEN $2 AND $3
                   ORDER BY time""",
                symbol, start_date, end_date
            )
        return pd.DataFrame(rows)
```

#### Strategy Base Class
```python
# src/strategies/base_strategy.py
from abc import ABC, abstractmethod
import pandas as pd
from typing import Dict, List

class BaseStrategy(ABC):
    def __init__(self, name: str, parameters: Dict = None):
        self.name = name
        self.parameters = parameters or {}
        
    @abstractmethod
    def generate_signals(self, data: pd.DataFrame) -> pd.Series:
        """Generate buy/sell signals based on market data"""
        pass
        
    @abstractmethod
    def calculate_position_size(self, signal: int, 
                              current_price: float, 
                              portfolio_value: float) -> int:
        """Calculate position size for a given signal"""
        pass
        
    def validate_parameters(self) -> bool:
        """Validate strategy parameters"""
        return True

# Example: Moving Average Crossover Strategy
class MovingAverageCrossover(BaseStrategy):
    def __init__(self, short_window: int = 10, long_window: int = 30):
        super().__init__("MA_Crossover", {
            "short_window": short_window,
            "long_window": long_window
        })
        
    def generate_signals(self, data: pd.DataFrame) -> pd.Series:
        short_ma = data['close'].rolling(self.parameters['short_window']).mean()
        long_ma = data['close'].rolling(self.parameters['long_window']).mean()
        
        signals = pd.Series(0, index=data.index)
        signals[short_ma > long_ma] = 1  # Buy signal
        signals[short_ma < long_ma] = -1  # Sell signal
        
        return signals.diff().fillna(0)  # Only signal on changes
```

#### Backtesting Engine
```python
# src/backtesting/backtest_engine.py
import pandas as pd
import numpy as np
from typing import Dict, List
from ..strategies.base_strategy import BaseStrategy

class BacktestEngine:
    def __init__(self, initial_capital: float = 100000):
        self.initial_capital = initial_capital
        self.results = {}
        
    async def run_backtest(self, strategy: BaseStrategy, 
                          data: pd.DataFrame, 
                          symbols: List[str]) -> Dict:
        """Run backtest for a given strategy and data"""
        portfolio_value = self.initial_capital
        positions = {symbol: 0 for symbol in symbols}
        trades = []
        equity_curve = []
        
        for date, row in data.iterrows():
            for symbol in symbols:
                if symbol in row.index:
                    symbol_data = data[data.index <= date].tail(100)  # Last 100 bars
                    signals = strategy.generate_signals(symbol_data)
                    
                    if len(signals) > 0:
                        latest_signal = signals.iloc[-1]
                        if latest_signal != 0:
                            # Execute trade
                            position_size = strategy.calculate_position_size(
                                latest_signal, row[symbol], portfolio_value
                            )
                            
                            trade = {
                                'date': date,
                                'symbol': symbol,
                                'signal': latest_signal,
                                'quantity': position_size,
                                'price': row[symbol]
                            }
                            trades.append(trade)
                            positions[symbol] += position_size
            
            # Calculate portfolio value
            current_value = self._calculate_portfolio_value(positions, row)
            equity_curve.append({'date': date, 'value': current_value})
            
        return self._calculate_performance_metrics(equity_curve, trades)
    
    def _calculate_performance_metrics(self, equity_curve: List, 
                                     trades: List) -> Dict:
        """Calculate comprehensive performance metrics"""
        df = pd.DataFrame(equity_curve)
        df.set_index('date', inplace=True)
        
        returns = df['value'].pct_change().dropna()
        
        total_return = (df['value'].iloc[-1] / df['value'].iloc[0]) - 1
        sharpe_ratio = np.sqrt(252) * returns.mean() / returns.std()
        max_drawdown = self._calculate_max_drawdown(df['value'])
        
        winning_trades = [t for t in trades if t['signal'] * 
                         (t['price'] - df.loc[t['date'], 'value']) > 0]
        win_rate = len(winning_trades) / len(trades) if trades else 0
        
        return {
            'total_return': total_return,
            'sharpe_ratio': sharpe_ratio,
            'max_drawdown': max_drawdown,
            'win_rate': win_rate,
            'total_trades': len(trades),
            'equity_curve': df.to_dict(),
            'trades': trades
        }
```

### 6. Performance Analysis & Reporting
```python
# src/analytics/performance_analyzer.py
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from typing import Dict, List

class PerformanceAnalyzer:
    def __init__(self):
        pass
        
    def generate_report(self, backtest_results: Dict) -> Dict:
        """Generate comprehensive performance report"""
        return {
            'summary_stats': self._calculate_summary_stats(backtest_results),
            'risk_metrics': self._calculate_risk_metrics(backtest_results),
            'trade_analysis': self._analyze_trades(backtest_results),
            'visualizations': self._create_visualizations(backtest_results)
        }
    
    def _calculate_summary_stats(self, results: Dict) -> Dict:
        """Calculate summary statistics"""
        equity_curve = pd.Series(results['equity_curve'])
        returns = equity_curve.pct_change().dropna()
        
        return {
            'total_return': results['total_return'],
            'annualized_return': (1 + results['total_return']) ** (252/len(equity_curve)) - 1,
            'volatility': returns.std() * np.sqrt(252),
            'sharpe_ratio': results['sharpe_ratio'],
            'max_drawdown': results['max_drawdown'],
            'calmar_ratio': results['total_return'] / abs(results['max_drawdown'])
        }
```

### 7. Digital Ocean Deployment

#### docker-compose.prod.yml
```yaml
version: '3.8'

services:
  app:
    build: .
    ports:
      - "8000:8000"
    environment:
      - DATABASE_URL=postgresql://user:pass@db:5432/trading_bot
      - REDIS_URL=redis://redis:6379/0
      - IB_HOST=host.docker.internal
      - IB_PORT=7497
    depends_on:
      - db
      - redis
    volumes:
      - ./logs:/app/logs
    restart: unless-stopped

  db:
    image: timescale/timescaledb:latest-pg14
    environment:
      POSTGRES_DB: trading_bot
      POSTGRES_USER: user
      POSTGRES_PASSWORD: pass
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql
    restart: unless-stopped

  redis:
    image: redis:7-alpine
    restart: unless-stopped

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
    depends_on:
      - app
    restart: unless-stopped

volumes:
  postgres_data:
```

### 8. API Endpoints Structure
```python
# src/api/main.py
from fastapi import FastAPI, Depends
from .routers import strategies, backtesting, portfolio, market_data

app = FastAPI(title="Trading Bot API", version="1.0.0")

app.include_router(strategies.router, prefix="/api/v1/strategies")
app.include_router(backtesting.router, prefix="/api/v1/backtesting")
app.include_router(portfolio.router, prefix="/api/v1/portfolio")
app.include_router(market_data.router, prefix="/api/v1/market-data")

@app.get("/health")
async def health_check():
    return {"status": "healthy"}
```

### 9. Development Workflow
1. **Setup**: Clone repository, open in VS Code with dev containers
2. **Database**: Run migrations to set up schema
3. **Development**: Implement strategies and test with paper trading
4. **Backtesting**: Run historical tests on 5-year data
5. **Deployment**: Deploy to Digital Ocean droplet
6. **Monitoring**: Set up logging and monitoring

### 10. Next Steps
1. Set up the development environment
2. Implement basic IB Gateway connection
3. Create database schema and migrations
4. Build your first strategy
5. Implement backtesting engine
6. Add performance analytics
7. Deploy to Digital Ocean

This architecture provides a solid foundation for your trading bot with all the components you specified. Would you like me to elaborate on any specific component or help you implement a particular part?