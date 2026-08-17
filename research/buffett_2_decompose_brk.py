#!/usr/bin/python3
# =============================================================================
# buffett_2_decompose_brk.py — BLAQUE BAUX BUFFETT #2: what IS Berkshire, in fragments?
#
# The real Buffett record (BRK.B) is the ground truth. Decompose its daily EXCESS
# returns onto the fragment factor ETFs (value/quality/safety/moat) plus the market.
# The AQR thesis predicts: market beta BELOW 1 (safe), positive loadings on value /
# quality / low-beta, and — once you account for the fragments — little unexplained
# alpha (Buffett is the fragments, levered, not magic). Test it on our data.
# Read-only. Prints its own results.
# =============================================================================
import os, sys
import numpy as np
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from _buffett_common import rets, stats, capm, ols, FRAG, MKT, CASH, BUFFETT

u, dates, R = rets(list(FRAG) + [MKT, CASH, BUFFETT]); j = {s: u.index(s) for s in u}
rf = R[:, j[CASH]]
brk_x = R[:, j[BUFFETT]] - rf
mkt_x = R[:, j[MKT]] - rf

print("=" * 78, "\nBUFFETT #2 — decomposing the real Buffett (BRK.B) onto the fragments\n" + "=" * 78)

sB, sM = stats(R[:, j[BUFFETT]]), stats(R[:, j[MKT]])
print(f"  BRK.B  Sharpe {sB['sh']:+.2f}  CAGR {sB['cagr']*100:+.1f}%  vol {sB['vol']*100:.1f}%  maxDD {sB['dd']*100:+.0f}%")
print(f"  SPY    Sharpe {sM['sh']:+.2f}  CAGR {sM['cagr']*100:+.1f}%  vol {sM['vol']*100:.1f}%  maxDD {sM['dd']*100:+.0f}%")

# single-factor: is Berkshire "safe" (market beta < 1) with alpha?
a1, b1 = capm(R[:, j[BUFFETT]], R[:, j[MKT]])
print(f"\n  CAPM (BRK.B on market): beta {b1:+.2f}  alpha {a1*100:+.1f}%/yr"
      f"   -> {'SAFE (beta<1)' if b1 < 1 else 'not safe'}")

# multivariate: BRK.B excess on the fragment excess returns
frags = list(FRAG)
X = np.column_stack([R[:, j[s]] - rf for s in frags])
alpha, betas, r2 = ols(brk_x, X)
print(f"\n  multi-factor (BRK.B excess on fragment excess returns):")
for s, b in zip(frags, betas):
    print(f"    {s:<5} ({FRAG[s]:<18}) loading {b:+.2f}")
print(f"    alpha {alpha*100:+.1f}%/yr    R^2 {r2:.2f}")

print("\nVERDICT: if BRK.B shows market beta < 1 (safe) with positive quality/value loadings and")
print("its alpha SHRINKS once the fragments are included, the AQR story holds on our data: Buffett")
print("is a cheap-safe-quality book, not sorcery. What's left as alpha is the part the tradable")
print("fragments do NOT capture (selection, private deals, and cheap FLOAT leverage — see #4).")
