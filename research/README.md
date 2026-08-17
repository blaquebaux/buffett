# Blaque Baux Buffett — research

First-pass Path-A research on **Buffett-in-fragments.** All sketches read Alpaca SIP daily bars, are
read-only, and print their own results. 2016-05 – 2026-08 (MOAT's inception bounds the window).

> **Data note, up front.** Alpaca serves *price bars, not fundamentals* — so we cannot build
> book-value / accruals / margin factors from scratch. Instead each fragment is its liquid **factor
> ETF** (a feature: these are tradable), and we decompose the **real Buffett record (BRK.B)** onto
> them: value→VLUE, quality→QUAL, safety/low-beta→USMV, moat/persistence→MOAT.

```bash
export $(grep -v '^#' ~/.config/blaquebaux/alpaca.env | xargs)   # or source it
python research/buffett_1_fragments.py       # which fragments still pay?
python research/buffett_2_decompose_brk.py   # what IS Berkshire, in fragments?  (the clean win)
python research/buffett_3_recombination.py   # does the blend beat its parts?
python research/buffett_4_leverage.py        # the float fragment, governed
```

## Scorecard

| # | Question | Result | Verdict |
|---|----------|--------|---------|
| 1 | Do the fragments beat the market? | SPY **+0.89** > QUAL +0.84 > MOAT +0.79 ≈ VLUE +0.78 > USMV +0.75; **all slightly negative alpha** | ❌ no fragment beat the cap-weighted market this decade |
| 2 | What *is* Berkshire, in fragments? | BRK.B **beta 0.79 (safe)**; loads **+0.55 low-beta, +0.32 value**; R² 0.60; **residual alpha +2.0%/yr** | ✅ **clean win** — the AQR "cheap + safe" story holds |
| 3 | Does the blend beat its parts? | blend **+0.83** ≈ best single (QUAL +0.84) < SPY +0.89; lower vol (16.7%) | ⚠️ diversifies vol, **not** Sharpe; quality carries it |
| 4 | Leverage / cheap float? | 1.6x safe book +0.77 vs 1.6x SPY **+0.84**; +3% margin drops it to +0.70 | ⚠️ scales, doesn't create Sharpe; **financing is decisive** |

## The synthesis

**The decomposition is a genuine, clean win; the forward-tradable recipe is an honest miss — and the
gap between them is the whole lesson.** Berkshire resolves almost textbook-perfectly into Buffett's
fragments: BRK.B runs a **market beta of 0.79** (safe, exactly as the legend says), loads most heavily
on **low-beta safety (+0.55)** and then **value (+0.32)**, and the fragments explain **60%** of its
returns. What's left is **~2%/yr of residual alpha** — the part no factor ETF captures: security
selection, private/preferred deals, and above all *cheap insurance float*. So "Buffett is cheap-safe
stocks, levered with free money, plus real selection" is **confirmed on our data**, not folklore.

But *use the best parts* — turning those fragments forward as tradable ETFs — did **not** beat the
market over 2016–2026. Not value, not quality, not low-vol, not moat, and **not even Buffett himself**
(BRK.B Sharpe **+0.73** vs SPY **+0.89**). This was the mega-cap-growth decade: the cap-weighted index
*was* the quality-growth juggernaut, so every explicit factor tilt came out as **defensive beta, not
alpha** (all four fragments posted slightly negative alpha to SPY). The recombination (#3) diversifies
*volatility* — the blend runs 16.7% vol vs the market's 17.6% — but it does not manufacture Sharpe;
quality is the best single piece and the four-way blend merely ties it. And the leverage fragment (#4)
confirms the base's law in a pointed way: leverage **scales return and drawdown together** (1.6x turns
the safe book's −33% drawdown into −49%), the **financing rate decides everything** (a +3% retail
spread erases the benefit — the base's *"leverage is net-negative at today's rates"*), and this decade
the highest-Sharpe book to lever was simply *the market* (Broad's territory), not the safe book.

**The usable takeaway is narrow and defensive:** low-vol (USMV) is a legitimate drawdown-control lever
(14.2% vol, −33% DD) — a *sizing/guardrail* tool, not a source of alpha — and the true Buffett edge
(**cheap float + selection**) is precisely the fragment a retail book **cannot** buy in a wrapper.
"Use the best parts" honestly resolves to: keep the risk reduction, not a market-beating tilt.

## Status
**Research: first pass complete — qualified** (`research/`). The BRK.B decomposition validates the
cheap-safe-quality story cleanly (a real positive result); but as forward tradable fragments none beat
the market this decade — defensive beta, not alpha — and Buffett's real moat (cheap float) is
un-buyable in an ETF. Usable piece: low-vol for defense. No standalone alpha keeper, no live driver;
nothing validated to the spine's bar.
