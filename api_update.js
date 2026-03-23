// ═══════════════════════════════════════════════════════════
//  /api/update.js — WAMY Data Updater
//  Runs on Vercel as both:
//    • Cron job (daily at 16:00 Rabat time via vercel.json)
//    • Manual trigger: GET /api/update?secret=YOUR_SECRET
// ═══════════════════════════════════════════════════════════

import { createClient } from '@supabase/supabase-js';

// ── Supabase admin client (uses SERVICE_ROLE key — server only, never expose) ──
const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

// ── Bourse de Casablanca official data sources ──
const BVC_SOURCES = {
  // Official BVC market data endpoint (public JSON)
  prices:  'https://www.casablanca-bourse.com/bourseweb/Negociation.aspx?Cat=21&IdLink=305',
  masi:    'https://www.casablanca-bourse.com/bourseweb/Indice.aspx?Cat=21&IdLink=203',
};

// ── All 78 tickers (must match stocks table) ──
const ALL_TICKERS = [
  'ATW','BOA','BCP','BMCI','CFG','CIH','CDM','SLF',
  'AFM','AGM','ATL','SAH','WAA',
  'MNG','CMT','SMI','SID','DHO','ZDJ',
  'CMA','LHM','GTM','TGC','COL','AFI','JET','DLM',
  'TQM','TMA','MOX','GAZ',
  'IAM','HPS','INV','M2M','DYT','DWY','IBC','MIC','SMM','CAP',
  'CSR','LBV','LES','MUT','OUL','CRS','DRI','UMR','SBM',
  'MSA','CTM','TIM',
  'ADH','ADI','ARD','BAL','IMO','RDS',
  'ATH','NEJ','NKL',
  'SNP','ALM','FBR','MDP','MAB','MLE','SRM',
  'AKT','PRO','SOT',
  'ALM2','EQD','REB','RIS','VAL',
  'SAM'
];

// ══════════════════════════════════════════════════════
//  SCRAPER: Fetch live prices from BVC
//  Returns array of { ticker, price, changePct, vol, cap }
// ══════════════════════════════════════════════════════
async function fetchBVCPrices() {
  try {
    // BVC publishes a downloadable CSV/Excel with daily prices.
    // We use their public "Résumé de la séance" page.
    // NOTE: If BVC blocks scraping, use a proxy or their official API partner.

    const response = await fetch(
      'https://www.casablanca-bourse.com/bourseweb/res/Syntheses/SyntheseValeurs.aspx',
      {
        headers: {
          'User-Agent': 'Mozilla/5.0 (compatible; WAMYBot/1.0)',
          'Accept': 'text/html,application/xhtml+xml',
        },
        signal: AbortSignal.timeout(15000),
      }
    );

    if (!response.ok) {
      console.warn('BVC fetch failed, using fallback mode');
      return null;
    }

    const html = await response.text();

    // Parse the HTML table — BVC uses a standard data table
    const rows = [];
    const tableMatch = html.match(/<table[^>]*id="GridView[^"]*"[^>]*>([\s\S]*?)<\/table>/i);
    if (!tableMatch) return null;

    const rowMatches = tableMatch[1].matchAll(/<tr[^>]*>([\s\S]*?)<\/tr>/gi);
    for (const rowMatch of rowMatches) {
      const cells = [...rowMatch[1].matchAll(/<td[^>]*>([\s\S]*?)<\/td>/gi)]
        .map(m => m[1].replace(/<[^>]+>/g, '').trim().replace(/\s+/g, ' '));

      if (cells.length >= 6) {
        const ticker = cells[0]?.toUpperCase();
        const price  = parseFloat(cells[2]?.replace(',', '.').replace(/\s/g, '')) || 0;
        const change = parseFloat(cells[3]?.replace(',', '.').replace('%','')) || 0;
        const vol    = formatVolume(cells[5]);

        if (ticker && ALL_TICKERS.includes(ticker) && price > 0) {
          rows.push({ ticker, price, changePct: change, vol });
        }
      }
    }

    return rows.length > 0 ? rows : null;
  } catch (err) {
    console.error('BVC scrape error:', err.message);
    return null;
  }
}

// ══════════════════════════════════════════════════════
//  FALLBACK: Try alternative data sources
// ══════════════════════════════════════════════════════
async function fetchFallbackPrices() {
  // Try Boursorama or another aggregator as fallback
  // This is a placeholder — integrate your preferred data provider
  console.log('Using fallback prices (static from last known values)');
  return null;
}

// ══════════════════════════════════════════════════════
//  UPSERT to Supabase
// ══════════════════════════════════════════════════════
async function upsertPrices(prices) {
  const today = new Date().toISOString().split('T')[0]; // YYYY-MM-DD
  const rows  = prices.map(p => ({
    ticker:     p.ticker,
    price:      p.price,
    change_pct: p.changePct || 0,
    volume:     p.vol || '—',
    cap:        p.cap || '—',
    ytd:        p.ytd || 0,
    trade_date: today,
    updated_at: new Date().toISOString(),
  }));

  const { data, error } = await supabase
    .from('stock_prices')
    .upsert(rows, { onConflict: 'ticker,trade_date' });

  if (error) throw new Error('Upsert error: ' + error.message);
  return rows.length;
}

async function upsertMASI(data) {
  const today = new Date().toISOString().split('T')[0];
  const { error } = await supabase
    .from('masi_index')
    .upsert([{
      index_name: 'MASI',
      value:      data.value,
      change_pct: data.changePct,
      volume:     data.volume,
      cap:        data.cap,
      fear_greed: data.fearGreed || 50,
      rsi_avg:    data.rsiAvg || 50,
      hausses:    data.hausses || 0,
      baisses:    data.baisses || 0,
      stables:    data.stables || 0,
      trade_date: today,
      updated_at: new Date().toISOString(),
    }], { onConflict: 'index_name,trade_date' });

  if (error) console.error('MASI upsert error:', error.message);
}

async function logRun(status, stocksUpdated, message) {
  await supabase.from('update_log').insert({
    source: 'vercel_cron',
    status,
    stocks_updated: stocksUpdated,
    message,
  });
}

// ══════════════════════════════════════════════════════
//  HELPER: format volume string (e.g. 2500000 → "2.5M")
// ══════════════════════════════════════════════════════
function formatVolume(raw) {
  const n = parseFloat(String(raw).replace(/[^\d.]/g, ''));
  if (isNaN(n)) return '—';
  if (n >= 1e9) return (n / 1e9).toFixed(2) + 'B';
  if (n >= 1e6) return (n / 1e6).toFixed(2) + 'M';
  if (n >= 1e3) return (n / 1e3).toFixed(1) + 'K';
  return String(n);
}

// ══════════════════════════════════════════════════════
//  MAIN HANDLER
// ══════════════════════════════════════════════════════
export default async function handler(req, res) {
  // Security: require secret for manual triggers (cron bypasses this automatically)
  const { secret } = req.query;
  const isCron     = req.headers['x-vercel-cron'] === '1';

  if (!isCron && secret !== process.env.UPDATE_SECRET) {
    return res.status(401).json({ error: 'Unauthorized' });
  }

  console.log(`[WAMY Update] Starting — ${new Date().toISOString()}`);

  try {
    // 1. Fetch prices
    let prices = await fetchBVCPrices();
    if (!prices) prices = await fetchFallbackPrices();

    if (!prices || prices.length === 0) {
      await logRun('error', 0, 'No data fetched from any source');
      return res.status(200).json({
        ok: false,
        message: 'No data available. Market may be closed or sources unreachable.',
        timestamp: new Date().toISOString(),
      });
    }

    // 2. Upsert prices
    const count = await upsertPrices(prices);

    // 3. Log success
    await logRun('ok', count, `Updated ${count} stocks from BVC`);

    console.log(`[WAMY Update] Done — ${count} stocks updated`);
    return res.status(200).json({
      ok: true,
      stocksUpdated: count,
      timestamp: new Date().toISOString(),
    });

  } catch (err) {
    console.error('[WAMY Update] Fatal error:', err.message);
    await logRun('error', 0, err.message);
    return res.status(500).json({ ok: false, error: err.message });
  }
}
