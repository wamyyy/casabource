-- ═══════════════════════════════════════════════════
--  WAMY — Bourse de Casablanca
--  Supabase Schema v1.0
-- ═══════════════════════════════════════════════════

-- ── EXTENSION ──
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ══════════════════════════════════════════
-- TABLE: stocks
-- Master list of all 78 listed companies
-- ══════════════════════════════════════════
CREATE TABLE IF NOT EXISTS public.stocks (
  ticker        TEXT PRIMARY KEY,
  name          TEXT NOT NULL,
  sector        TEXT NOT NULL,
  rank          INTEGER,
  domain        TEXT,
  div           NUMERIC DEFAULT 0,
  div_yield     NUMERIC DEFAULT 0,
  div_freq      TEXT DEFAULT 'Annuel',
  div_date      TEXT DEFAULT '—',
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- ══════════════════════════════════════════
-- TABLE: stock_prices
-- Daily price data per company
-- ══════════════════════════════════════════
CREATE TABLE IF NOT EXISTS public.stock_prices (
  id          BIGSERIAL PRIMARY KEY,
  ticker      TEXT NOT NULL REFERENCES public.stocks(ticker) ON DELETE CASCADE,
  price       NUMERIC NOT NULL,
  change_pct  NUMERIC DEFAULT 0,      -- % variation vs previous close
  volume      TEXT DEFAULT '0',        -- e.g. "2.5M"
  cap         TEXT DEFAULT '—',        -- e.g. "149.0B"
  ytd         NUMERIC DEFAULT 0,       -- year-to-date %
  trade_date  DATE NOT NULL DEFAULT CURRENT_DATE,
  updated_at  TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(ticker, trade_date)
);

-- Index for fast latest-price queries
CREATE INDEX IF NOT EXISTS idx_prices_ticker_date
  ON public.stock_prices(ticker, trade_date DESC);

-- ══════════════════════════════════════════
-- TABLE: masi_index
-- MASI + MADEX daily snapshots
-- ══════════════════════════════════════════
CREATE TABLE IF NOT EXISTS public.masi_index (
  id            BIGSERIAL PRIMARY KEY,
  index_name    TEXT NOT NULL,          -- 'MASI' or 'MADEX'
  value         NUMERIC NOT NULL,
  change_pct    NUMERIC DEFAULT 0,
  volume        TEXT DEFAULT '0',
  cap           TEXT DEFAULT '—',
  fear_greed    INTEGER DEFAULT 50,     -- 0-100
  rsi_avg       NUMERIC DEFAULT 50,     -- 0-100
  hausses       INTEGER DEFAULT 0,
  baisses       INTEGER DEFAULT 0,
  stables       INTEGER DEFAULT 0,
  trade_date    DATE NOT NULL DEFAULT CURRENT_DATE,
  updated_at    TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(index_name, trade_date)
);

-- ══════════════════════════════════════════
-- TABLE: watchlist
-- Per-user saved favorites
-- ══════════════════════════════════════════
CREATE TABLE IF NOT EXISTS public.watchlist (
  id          BIGSERIAL PRIMARY KEY,
  user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  ticker      TEXT NOT NULL REFERENCES public.stocks(ticker) ON DELETE CASCADE,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, ticker)
);

-- ══════════════════════════════════════════
-- TABLE: update_log
-- Tracks every cron/scraper run
-- ══════════════════════════════════════════
CREATE TABLE IF NOT EXISTS public.update_log (
  id          BIGSERIAL PRIMARY KEY,
  run_at      TIMESTAMPTZ DEFAULT NOW(),
  source      TEXT DEFAULT 'cron',
  status      TEXT DEFAULT 'ok',       -- 'ok' | 'error' | 'partial'
  stocks_updated INTEGER DEFAULT 0,
  message     TEXT
);

-- ══════════════════════════════════════════
-- ROW LEVEL SECURITY
-- ══════════════════════════════════════════

-- stocks: public read, no public write
ALTER TABLE public.stocks ENABLE ROW LEVEL SECURITY;
CREATE POLICY "stocks_public_read" ON public.stocks
  FOR SELECT USING (true);

-- stock_prices: public read
ALTER TABLE public.stock_prices ENABLE ROW LEVEL SECURITY;
CREATE POLICY "prices_public_read" ON public.stock_prices
  FOR SELECT USING (true);

-- masi_index: public read
ALTER TABLE public.masi_index ENABLE ROW LEVEL SECURITY;
CREATE POLICY "masi_public_read" ON public.masi_index
  FOR SELECT USING (true);

-- watchlist: users see only their own rows
ALTER TABLE public.watchlist ENABLE ROW LEVEL SECURITY;
CREATE POLICY "watchlist_owner_read" ON public.watchlist
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "watchlist_owner_insert" ON public.watchlist
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "watchlist_owner_delete" ON public.watchlist
  FOR DELETE USING (auth.uid() = user_id);

-- update_log: service role only (no public access)
ALTER TABLE public.update_log ENABLE ROW LEVEL SECURITY;

-- ══════════════════════════════════════════
-- VIEWS
-- ══════════════════════════════════════════

-- latest_prices: join stocks + most recent price row
CREATE OR REPLACE VIEW public.latest_prices AS
SELECT
  s.ticker,
  s.name,
  s.sector,
  s.rank,
  s.domain,
  s.div,
  s.div_yield,
  s.div_freq,
  s.div_date,
  p.price,
  p.change_pct   AS "change",
  p.volume       AS vol,
  p.cap,
  p.ytd,
  p.trade_date,
  p.updated_at
FROM public.stocks s
LEFT JOIN public.stock_prices p
  ON s.ticker = p.ticker
  AND p.trade_date = (
    SELECT MAX(trade_date)
    FROM public.stock_prices sp2
    WHERE sp2.ticker = s.ticker
  )
ORDER BY s.rank ASC NULLS LAST;

-- Grant anon/authenticated access to view
GRANT SELECT ON public.latest_prices TO anon, authenticated;
GRANT SELECT ON public.stocks TO anon, authenticated;
GRANT SELECT ON public.stock_prices TO anon, authenticated;
GRANT SELECT ON public.masi_index TO anon, authenticated;
GRANT ALL ON public.watchlist TO authenticated;
