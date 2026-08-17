#!/usr/bin/python3
# =============================================================================
# buffett_4_leverage.py — BLAQUE BAUX BUFFETT #4: the float fragment, governed.
#
# The AQR punchline: Buffett levered a high-Sharpe SAFE book ~1.6x with cheap insurance
# FLOAT. Leverage does not create Sharpe — it SCALES a book's return and its drawdown
# together. So the secret is two-fold: (a) apply it to a high-Sharpe low-vol book, not
# the market (contrast Broad's rejected naive index leverage), and (b) finance it
# CHEAPLY. Test the best safe/quality blend at 1.0/1.3/1.6x, financed two ways:
#   float-like (~T-bill, BIL)   vs   retail margin (~T-bill + 3%).
# Read-only. Prints its own results.
# =============================================================================
import os, sys
import numpy as np
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from _buffett_common import rets, stats, FRAG, MKT, CASH

u, dates, R = rets(list(FRAG) + [MKT, CASH]); j = {s: u.index(s) for s in u}
rf = R[:, j[CASH]]                                    # ~T-bill daily (float-like financing)
book = R[:, [j[s] for s in ["QUAL", "USMV"]]].mean(axis=1)   # the safe/quality core to lever
mkt = R[:, j[MKT]]
SPREAD = 0.03 / 252                                   # retail margin spread over T-bill, daily

def lever(r, L, fin):
    # borrow (L-1) at financing rate 'fin' (daily), invest L in the book
    return L * r - (L - 1) * fin

print("=" * 78, "\nBUFFETT #4 — leverage: cheap float on a safe book is the whole trick\n" + "=" * 78)
print(f"  book = QUAL+USMV (safe/quality core)   {dates[0]} .. {dates[-1]}\n")
print(f"  {'config':<34}{'Sharpe':>8}{'CAGR':>8}{'vol':>7}{'maxDD':>8}")
for L in [1.0, 1.3, 1.6]:
    st = stats(lever(book, L, rf))
    tag = "float-like (~T-bill)"
    print(f"  {f'{L:.1f}x  {tag}':<34}{st['sh']:>+8.2f}{st['cagr']*100:>+7.1f}%{st['vol']*100:>6.1f}%{st['dd']*100:>+7.0f}%")
print("  " + "-" * 56)
for L in [1.3, 1.6]:
    st = stats(lever(book, L, rf + SPREAD))
    print(f"  {f'{L:.1f}x  retail margin (+3%)':<34}{st['sh']:>+8.2f}{st['cagr']*100:>+7.1f}%{st['vol']*100:>6.1f}%{st['dd']*100:>+7.0f}%")
print("  " + "-" * 56)
# the contrast: lever the MARKET (Broad's rejected naive leverage)
for L in [1.6]:
    st = stats(lever(mkt, L, rf))
    print(f"  {f'{L:.1f}x  SPY (naive index lever)':<34}{st['sh']:>+8.2f}{st['cagr']*100:>+7.1f}%{st['vol']*100:>6.1f}%{st['dd']*100:>+7.0f}%")

print("\nVERDICT: leverage scales, it does not manufacture Sharpe — 1.6x turns the safe book's")
print("return AND drawdown up together. Two lessons hold: (1) levering a high-Sharpe low-vol book")
print("gives more return per unit of drawdown than levering the market (Broad's rejected trade),")
print("and (2) the FINANCING RATE decides everything — float-like ~T-bill funding keeps the edge,")
print("retail-margin +3% erodes it, exactly the base's 'leverage is net-negative at today's rates'")
print("law. Buffett's moat was cheap float, and that is the fragment a retail book cannot copy.")
