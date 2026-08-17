#!/usr/bin/python3
# =============================================================================
# buffett_3_recombination.py — BLAQUE BAUX BUFFETT #3: do the fragments recombine well?
#
# Buffett's engine is the BLEND (cheap x safe x quality), not any one piece. Build the
# equal-weight blend of the fragments (daily rebalance) and test whether the
# combination diversifies — i.e. beats the best single fragment and the market on a
# risk-adjusted basis — or whether one fragment is quietly carrying it.
# Read-only. Prints its own results.
# =============================================================================
import os, sys
import numpy as np
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from _buffett_common import rets, stats, capm, FRAG, MKT, BUFFETT

u, dates, R = rets(list(FRAG) + [MKT, BUFFETT]); j = {s: u.index(s) for s in u}
frags = list(FRAG)
blend = R[:, [j[s] for s in frags]].mean(axis=1)                 # cheap x safe x quality x moat
qsv = R[:, [j[s] for s in ["QUAL", "USMV", "VLUE"]]].mean(axis=1)  # the classic 3-fragment Buffett core

print("=" * 78, "\nBUFFETT #3 — recombination: does the blend beat its parts?\n" + "=" * 78)
print(f"  {dates[0]} .. {dates[-1]}   daily-rebalanced equal-weight blends\n")
print(f"  {'book':<28}{'Sharpe':>8}{'CAGR':>8}{'vol':>7}{'maxDD':>8}{'alpha':>8}")
mkt = R[:, j[MKT]]
def line(lbl, r):
    st = stats(r); a, _ = capm(r, mkt)
    print(f"  {lbl:<28}{st['sh']:>+8.2f}{st['cagr']*100:>+7.1f}%{st['vol']*100:>6.1f}%{st['dd']*100:>+7.0f}%{a*100:>+7.1f}%")

for s in frags: line(f"{s} ({FRAG[s]})", R[:, j[s]])
print("  " + "-" * 62)
line("blend (4 fragments)", blend)
line("core (QUAL+USMV+VLUE)", qsv)
line("SPY (the market)", mkt)
line("BRK.B (the man)", R[:, j[BUFFETT]])

best_frag = max(frags, key=lambda s: stats(R[:, j[s]])['sh'])
bfsh = stats(R[:, j[best_frag]])['sh']
print(f"\nVERDICT: best single fragment = {best_frag} (Sharpe {bfsh:+.2f}); blend Sharpe {stats(blend)['sh']:+.2f}.")
print("If the blend's Sharpe beats the best single part, the fragments DIVERSIFY (the combination")
print("is the edge, as Buffett intends). If not, one fragment (usually quality/low-vol) is carrying")
print("it and the honest sleeve is that fragment, governed — not a four-way blend for its own sake.")
