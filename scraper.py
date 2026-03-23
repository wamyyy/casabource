"""
╔══════════════════════════════════════════════════════════╗
║  WAMY — BVC Scraper                                      ║
║  Source: LeBoursier.ma via BVCscrap library              ║
║  Target: Supabase (stock_prices + masi_index tables)     ║
║                                                          ║
║  Run manually:  python scraper.py                        ║
║  Run on cron:   0 16 * * 1-5  (16h00 Rabat = after close)║
╚══════════════════════════════════════════════════════════╝
"""

import os
import time
import datetime
import json
import requests

# ── Install check ──
try:
    import BVCscrap as bvc
    import pandas as pd
    from supabase import create_client, Client
except ImportError as e:
    print(f"""
❌ Missing dependency: {e}

Run this first:
    pip install BVCscrap pandas supabase python-dotenv
""")
    exit(1)

try:
    from dotenv import load_dotenv
    load_dotenv()
except ImportError:
    pass  # .env optional

# ══════════════════════════════════════════
# CONFIG — reads from .env or environment
# ══════════════════════════════════════════
SUPABASE_URL          = os.environ.get("SUPABASE_URL",          "https://uvxrsdybplnndwuzixef.supabase.co")
SUPABASE_SERVICE_KEY  = os.environ.get("SUPABASE_SERVICE_ROLE_KEY", "")  # ← paste your service_role key here

if not SUPABASE_SERVICE_KEY:
    print("""
❌ SUPABASE_SERVICE_ROLE_KEY is missing!

Either:
  1. Create a .env file with: SUPABASE_SERVICE_ROLE_KEY=your_key
  2. Or set it directly in this script (line below)
""")
    # ↓ uncomment and paste your service_role key if you don't use .env
    # SUPABASE_SERVICE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...."
    exit(1)

# ── BVCscrap ticker map ──
# BVCscrap uses full names — we map them to our tickers
TICKER_MAP = {
    'Addoha':          'ADH',
    'AFMA':            'AFM',
    'Afric Indus':     'AFI',
    'Afriquia Gaz':    'GAZ',
    'Agma':            'AGM',
    'Akdital':         'AKT',
    'Alliances':       'ADI',
    'Aluminium Maroc': 'ALM',
    'Aradei Capital':  'ARD',
    'Atlanta':         'ATL',
    'Attijariwafa':    'ATW',
    'Auto Hall':       'ATH',
    'Auto Nejma':      'NEJ',
    'Balima':          'BAL',
    'BCP':             'BCP',
    'BMCI':            'BMCI',
    'BOA':             'BOA',
    'Cartier Saada':   'CRS',
    'Cash Plus':       'CAP',
    'CFG Bank':        'CFG',
    'CIH':             'CIH',
    'Ciments Maroc':   'CMA',
    'Colorado':        'COL',
    'Cosumar':         'CSR',
    'Credit Maroc':    'CDM',
    'CTM':             'CTM',
    'Dari Couspate':   'DRI',
    'Delta Holding':   'DHO',
    'Disway':          'DWY',
    'Disty Tech':      'DYT',
    'Ennakl':          'NKL',
    'Eqdom':           'EQD',
    'Fenie Brossette': 'FBR',
    'HPS':             'HPS',
    'IB Maroc':        'IBC',
    'Immorente':       'IMO',
    'Involys':         'INV',
    'Itissalat':       'IAM',
    'Jet Contractors': 'JET',
    'Label Vie':       'LBV',
    'LafargeHolcim':   'LHM',
    'Lesieur Cristal': 'LES',
    'Maghrebail':      'MAB',
    'Maghreb Oxygene': 'MOX',
    'Managem':         'MNG',
    'Maroc Leasing':   'MLE',
    'Marsa Maroc':     'MSA',
    'Med Paper':       'MDP',
    'Microdata':       'MIC',
    'Miniere Touissit':'CMT',
    'Mutandis':        'MUT',
    'Oulmes':          'OUL',
    'Promopharm':      'PRO',
    'Rebab':           'REB',
    'Residences DS':   'RDS',
    'Risma':           'RIS',
    'Salafin':         'SLF',
    'Sanlam':          'SAH',
    'SGTM':            'GTM',
    'SMI':             'SMI',
    'SM Monetique':    'SMM',
    'Snep':            'SNP',
    'Sonasid':         'SID',
    'Sothema':         'SOT',
    'Taqa Morocco':    'TQM',
    'TGCC':            'TGC',
    'Timar':           'TIM',
    'Total Maroc':     'TMA',
    'Unimer':          'UMR',
    'Valoris':         'VAL',
    'Wafa Assurance':  'WAA',
    'Zellidja':        'ZDJ',
}

# ══════════════════════════════════════════
# HELPERS
# ══════════════════════════════════════════
def fmt_volume(val):
    """Convert raw volume number to readable string: 2500000 → '2.50M'"""
    try:
        n = float(str(val).replace(',', '.').replace(' ', ''))
        if n >= 1e9:  return f"{n/1e9:.2f}B"
        if n >= 1e6:  return f"{n/1e6:.2f}M"
        if n >= 1e3:  return f"{n/1e3:.1f}K"
        return str(int(n))
    except:
        return "—"

def fmt_cap(price, nb_shares):
    """Estimate market cap from price × nb_shares"""
    try:
        cap = float(price) * float(nb_shares)
        if cap >= 1e12: return f"{cap/1e12:.1f}T"
        if cap >= 1e9:  return f"{cap/1e9:.1f}B"
        if cap >= 1e6:  return f"{cap/1e6:.1f}M"
        return "—"
    except:
        return "—"

def safe_float(val, default=0.0):
    try:
        return round(float(str(val).replace(',', '.').replace('%', '').strip()), 4)
    except:
        return default

# ══════════════════════════════════════════
# SCRAPER
# ══════════════════════════════════════════
def scrape_all_stocks():
    """
    Use BVCscrap to get today's session data for all stocks.
    Returns list of dicts ready for Supabase upsert.
    """
    print("📡 Getting notation list from BVCscrap...")
    try:
        names = bvc.notation()
    except Exception as e:
        print(f"❌ Failed to get notation: {e}")
        return [], None

    print(f"✅ Found {len(names)} stocks in notation list")

    today      = datetime.date.today().isoformat()
    results    = []
    errors     = []
    start_ytd  = f"{datetime.date.today().year}-01-01"

    # Get MASI index data
    masi_data = None
    try:
        print("📊 Fetching MASI index...")
        masi_df = bvc.loadata('MASI', start=start_ytd)
        if masi_df is not None and not masi_df.empty:
            latest_masi = masi_df.iloc[-1]
            prev_masi   = masi_df.iloc[-2] if len(masi_df) > 1 else masi_df.iloc[-1]
            masi_val    = safe_float(latest_masi['Value'])
            masi_prev   = safe_float(prev_masi['Value'])
            masi_chg    = round((masi_val - masi_prev) / masi_prev * 100, 2) if masi_prev else 0
            masi_data   = {
                'index_name': 'MASI',
                'value':      masi_val,
                'change_pct': masi_chg,
                'trade_date': today,
            }
            print(f"✅ MASI: {masi_val:,.2f} ({masi_chg:+.2f}%)")
    except Exception as e:
        print(f"⚠️  MASI fetch error: {e}")

    # Get individual stock data
    print(f"\n📈 Fetching {len(names)} stocks...")
    print("─" * 50)

    for i, bvc_name in enumerate(names):
        if bvc_name in ('MASI', 'MSI20'):
            continue

        ticker = None
        # Try to match name to our ticker map
        for key, val in TICKER_MAP.items():
            if key.lower() in bvc_name.lower() or bvc_name.lower() in key.lower():
                ticker = val
                break

        if not ticker:
            print(f"  ⚠️  No ticker match for '{bvc_name}' — skipping")
            continue

        try:
            # getCours gives us today's session data
            cours_data = bvc.getCours(bvc_name)
            session    = cours_data.get('Données_Seance', {})

            if not session:
                print(f"  ⚠️  {ticker}: no session data")
                continue

            # Parse session data
            # Keys vary slightly — try multiple
            price  = safe_float(session.get('Cours', session.get('Dernier', session.get('Cloture', 0))))
            change = safe_float(session.get('Variation', session.get('Var', 0)))
            vol    = fmt_volume(session.get('Volume', session.get('Qte', 0)))

            if price <= 0:
                # Try historical fallback
                hist = bvc.loadata(bvc_name)
                if hist is not None and not hist.empty:
                    price  = safe_float(hist.iloc[-1]['Value'])
                    change = safe_float(hist.iloc[-1].get('Variation', 0))
                    vol_raw = hist.iloc[-1].get('Volume', 0)
                    vol    = fmt_volume(vol_raw)

            # YTD calculation
            ytd = 0.0
            try:
                hist_ytd = bvc.loadata(bvc_name, start=start_ytd)
                if hist_ytd is not None and len(hist_ytd) >= 2:
                    first_price = safe_float(hist_ytd.iloc[0]['Value'])
                    last_price  = safe_float(hist_ytd.iloc[-1]['Value'])
                    if first_price > 0:
                        ytd = round((last_price - first_price) / first_price * 100, 2)
            except:
                pass

            results.append({
                'ticker':     ticker,
                'price':      price,
                'change_pct': change,
                'volume':     vol,
                'cap':        '—',   # We don't have nb_shares easily
                'ytd':        ytd,
                'trade_date': today,
            })

            status = f"✅ {ticker:6s}  {price:>10.2f} MAD  {change:+.2f}%  YTD: {ytd:+.2f}%"
            print(f"  {status}")

            # Polite delay — avoid hammering the server
            time.sleep(0.3)

        except Exception as e:
            errors.append((ticker or bvc_name, str(e)))
            print(f"  ❌ {ticker or bvc_name}: {e}")

    print(f"\n{'─'*50}")
    print(f"✅ Scraped: {len(results)} stocks")
    if errors:
        print(f"❌ Errors:  {len(errors)} stocks: {[e[0] for e in errors]}")

    return results, masi_data


# ══════════════════════════════════════════
# SUPABASE UPLOADER
# ══════════════════════════════════════════
def push_to_supabase(stocks: list, masi_data: dict):
    print(f"\n🚀 Pushing {len(stocks)} stocks to Supabase...")

    try:
        sb: Client = create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)
    except Exception as e:
        print(f"❌ Supabase connection failed: {e}")
        return False

    errors = []

    # Upload stock prices in batches of 20
    batch_size = 20
    for i in range(0, len(stocks), batch_size):
        batch = stocks[i:i + batch_size]
        try:
            result = sb.table('stock_prices').upsert(
                batch,
                on_conflict='ticker,trade_date'
            ).execute()
            print(f"  ✅ Batch {i//batch_size + 1}: {len(batch)} rows upserted")
        except Exception as e:
            errors.append(str(e))
            print(f"  ❌ Batch {i//batch_size + 1} error: {e}")

    # Upload MASI data
    if masi_data:
        try:
            sb.table('masi_index').upsert(
                [masi_data],
                on_conflict='index_name,trade_date'
            ).execute()
            print(f"  ✅ MASI index upserted")
        except Exception as e:
            print(f"  ❌ MASI upsert error: {e}")

    # Log the run
    try:
        sb.table('update_log').insert({
            'source':         'python_scraper',
            'status':         'ok' if not errors else 'partial',
            'stocks_updated': len(stocks),
            'message':        f"Scraped {len(stocks)} stocks via BVCscrap/LeBoursier"
                              + (f" | Errors: {errors[:3]}" if errors else "")
        }).execute()
    except Exception as e:
        print(f"  ⚠️  Log error (non-critical): {e}")

    print(f"\n{'═'*50}")
    print(f"🎉 Done! {len(stocks) - len(errors)} stocks updated in Supabase")
    print(f"{'═'*50}")
    return True


# ══════════════════════════════════════════
# MAIN
# ══════════════════════════════════════════
if __name__ == '__main__':
    start_time = time.time()
    now        = datetime.datetime.now()

    print(f"""
╔══════════════════════════════════════════╗
║  WAMY Scraper — {now.strftime('%Y-%m-%d %H:%M')}           ║
║  Source: LeBoursier.ma (BVCscrap)        ║
║  Target: Supabase → stock_prices         ║
╚══════════════════════════════════════════╝
""")

    # Check if market is closed (run after 15:30 Rabat)
    rabat_hour = (now.hour + 1) % 24  # rough UTC+1
    is_weekday = now.weekday() < 5    # Mon=0 ... Fri=4

    if not is_weekday:
        print("⚠️  Today is weekend — no trading data available")
        print("   Running anyway to test the pipeline...\n")

    # 1. Scrape
    stocks, masi_data = scrape_all_stocks()

    if not stocks:
        print("❌ No data scraped — aborting")
        exit(1)

    # 2. Push to Supabase
    success = push_to_supabase(stocks, masi_data)

    elapsed = round(time.time() - start_time, 1)
    print(f"\n⏱️  Total time: {elapsed}s")

    exit(0 if success else 1)
