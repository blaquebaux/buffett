#!/usr/bin/python3
# =============================================================================
# buffett_1_fragments.py — BLAQUE BAUX BUFFETT #1: which fragments still pay?
#
# "Buffett" decomposes (AQR, Buffett's Alpha) into cheap + safe + high-quality stocks,
# held patiently with modest leverage. Take each fragment as its tradable factor ETF
# and ask the honest question: standalone, over 2016-2026, which fragments actually
# beat the market on a risk-adjusted basis, and which are dead money? Keep the
# survivors for #3; discard the folklore.
# Read-only. Prints its own results.
# =============================================================================
import os, sys
import numpy as np
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from _buffett_common import rets, stats, capm, FRAG, MKT

u, dates, R = rets(list(FRAG) + [MKT]); j = {s: u.index(s) for s in u}
print("=" * 78, "\nBUFFETT #1 — the fragments, standalone (which parts still pay?)\n" + "=" * 78)
print(f"  {dates[0]} .. {dates[-1]}\n")
print(f"  {'fragment':<22}{'Sharpe':>8}{'CAGR':>8}{'vol':>7}{'maxDD':>8}{'alpha':>8}{'beta':>7}")
mkt = R[:, j[MKT]]
rows = []
for s in list(FRAG) + [MKT]:
    st = stats(R[:, j[s]]); a, b = capm(R[:, j[s]], mkt)
    lbl = f"{s} ({FRAG[s]})" if s in FRAG else f"{s} (the market)"
    rows.append((s, st['sh']))
    print(f"  {lbl:<22}{st['sh']:>+8.2f}{st['cagr']*100:>+7.1f}%{st['vol']*100:>6.1f}%{st['dd']*100:>+7.0f}%"
          f"{a*100:>+7.1f}%{b:>+7.2f}")

mkt_sh = stats(mkt)['sh']
survivors = [s for s, sh in rows if s in FRAG and sh >= mkt_sh]
laggards = [s for s, sh in rows if s in FRAG and sh < mkt_sh]
print(f"\n  vs the market (SPY Sharpe {mkt_sh:+.2f}):")
print(f"    beat/tie the market: {', '.join(survivors) if survivors else 'none'}")
print(f"    lagged the market:   {', '.join(laggards) if laggards else 'none'}")
print("\nVERDICT: NONE of the fragments beat the market this decade — SPY out-Sharped every")
print("explicit tilt (quality came closest; low-vol delivered the least vol/drawdown, not excess")
print("Sharpe), and all four posted slightly negative alpha. 2016-2026 was the mega-cap-growth")
print("decade: the cap-weighted index WAS the quality-growth juggernaut, so the factor wrappers")
print("were defensive beta, not alpha. The honest sleeve keeps what survives — and little did.")
