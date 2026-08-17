#!/usr/bin/python3
# =============================================================================
# _buffett_common.py — shared helpers for the Blaque Baux Buffett sketches.
# Alpaca SIP daily bars; reads ALPACA_KEY_ID / ALPACA_SECRET_KEY from env. Read-only.
#
# DATA NOTE, up front: Alpaca serves PRICE bars, not fundamentals — so we cannot build
# book-value / accruals / margin factors from scratch. Instead we use the liquid FACTOR
# ETFs as tradable proxies for Buffett's fragments (this is a feature: they are things a
# book can actually hold), and we decompose the REAL Buffett record (BRK.B) onto them.
#   value  -> VLUE   quality -> QUAL   safety/low-beta -> USMV   moat/persistence -> MOAT
#   market -> SPY    cash/financing -> BIL           the man himself -> BRK.B
# =============================================================================
import os, json, urllib.request, math
import numpy as np

H = {"APCA-API-KEY-ID": os.environ["ALPACA_KEY_ID"], "APCA-API-SECRET-KEY": os.environ["ALPACA_SECRET_KEY"]}
START, END = "2016-01-01", "2026-08-01"
_cache = {}

FRAG = {"VLUE": "value", "QUAL": "quality", "USMV": "safety (low-beta)", "MOAT": "moat / persistence"}
MKT, CASH, BUFFETT = "SPY", "BIL", "BRK.B"

def bars(s):
    if s in _cache: return _cache[s]
    u = (f"https://data.alpaca.markets/v2/stocks/bars?symbols={s}&timeframe=1Day"
         f"&start={START}&end={END}&adjustment=all&feed=sip&limit=10000")
    try:
        d = json.load(urllib.request.urlopen(urllib.request.Request(u, headers=H), timeout=40))
        _cache[s] = {b["t"][:10]: b for b in d.get("bars", {}).get(s, [])}
    except Exception:
        _cache[s] = {}
    return _cache[s]

def rets(syms):
    D = {s: bars(s) for s in syms}; D = {s: v for s, v in D.items() if len(v) > 250}
    u = list(D); dates = sorted(set.intersection(*[set(D[s]) for s in u]))
    M = np.array([[D[s][d]["c"] for s in u] for d in dates], float)
    return u, dates[1:], M[1:] / M[:-1] - 1

def stats(r):
    r = np.asarray(r, float); r = r[np.isfinite(r)]
    if len(r) < 30 or r.std() == 0: return dict(sh=float('nan'), cagr=float('nan'), dd=float('nan'), vol=float('nan'))
    cum = np.cumprod(1 + r)
    return dict(sh=r.mean() / r.std() * math.sqrt(252), cagr=cum[-1] ** (252 / len(r)) - 1,
                dd=(cum / np.maximum.accumulate(cum) - 1).min(), vol=r.std() * math.sqrt(252))

def capm(y, x):
    """single-factor alpha (annualized) and beta of y on x."""
    y = np.asarray(y, float); x = np.asarray(x, float)
    m = np.isfinite(y) & np.isfinite(x); y, x = y[m], x[m]
    if len(y) < 30 or np.var(x) == 0: return float('nan'), float('nan')
    b = np.cov(y, x)[0, 1] / np.var(x)
    return (y.mean() - b * x.mean()) * 252, b

def ols(y, X):
    """multivariate OLS with intercept. Returns (alpha_annualized, betas dict-order, R2)."""
    y = np.asarray(y, float); X = np.asarray(X, float)
    A = np.column_stack([np.ones(len(y)), X])
    coef, *_ = np.linalg.lstsq(A, y, rcond=None)
    resid = y - A @ coef
    r2 = 1 - resid.var() / y.var()
    return coef[0] * 252, coef[1:], r2
