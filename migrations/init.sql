-- Enable TimescaleDB extension
CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE;

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

-- Convert to hypertable for time-series optimization
SELECT create_hypertable('price_data', 'time');

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

-- Convert to hypertable
SELECT create_hypertable('historical_data', 'time');

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

-- Insert some sample symbols
INSERT INTO symbols (symbol, exchange, currency) VALUES
    ('AAPL', 'NASDAQ', 'USD'),
    ('GOOGL', 'NASDAQ', 'USD'),
    ('MSFT', 'NASDAQ', 'USD'),
    ('TSLA', 'NASDAQ', 'USD'),
    ('SPY', 'ARCA', 'USD'),
    ('QQQ', 'NASDAQ', 'USD');

-- Create indexes for performance
CREATE INDEX idx_price_data_symbol_time ON price_data (symbol_id, time DESC);
CREATE INDEX idx_historical_data_symbol_time ON historical_data (symbol_id, time DESC);
CREATE INDEX idx_trades_account_time ON trades (account_id, executed_at DESC);
CREATE INDEX idx_positions_account ON positions (account_id);
CREATE INDEX idx_backtest_runs_strategy ON backtest_runs (strategy_id);
