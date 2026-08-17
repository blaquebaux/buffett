# Blaque Baux Buffett

**Buffett's strategy in fragments — isolate the parts that actually carry the premium.**

Buffett is a member of the Blaque Baux family. The [core repo](https://github.com/blaquebaux/base)
is the **engine and blueprint** — a governed, systematic platform (Julia) with a venue-agnostic
execution controller and a Layer-3 live-money safety gate. Buffett points that engine in its own
direction and inherits the governance wholesale.

> **Not investment advice.** Educational/research software. Nothing here is validated. See [LICENSE](LICENSE).

```bash
git clone --recursive https://github.com/blaquebaux/buffett.git
julia --project=engine -e 'using Pkg; Pkg.instantiate()'   # one-time engine setup
```

## The thesis

"Buffett" is treated as a monolith — buy wonderful companies at fair prices, hold forever. But the
academic decomposition (AQR's *Buffett's Alpha*) shows the record is not magic: it is **cheap, safe,
high-quality stocks, held with patience and modest leverage** (~1.6x, financed cheaply through
insurance float). The alpha is real, but it is *assembled* from components that are each measurable.

Buffett takes that literally: **break the strategy into fragments and use the best parts.** Separate
the pieces — value (paying a fair price), quality (high, stable profitability, low accruals), safety
(low beta, low leverage), moat/persistence (durable margins), and the leverage-through-float
mechanic — and test each on its own for whether it *still* holds up out of sample. Then recombine
only the fragments that survive, under the engine's governance. The goal is not to imitate Berkshire;
it is to keep what the data still supports and discard the folklore.

## Research plan (Path A)

- **The five fragments.** Build clean, cross-sectional proxies for value, quality, safety (low-beta),
  moat/persistence, and leverage-financing-cost. Measure each fragment's standalone premium, net of
  cost, on the base's purged K-fold / walk-forward bar.
- **Which parts still pay?** Quality and low-beta ("betting against beta") have held up better than
  raw value in the last decade — confirm or refute on our data, and keep only the survivors.
- **Recombination.** Test the quality×value×safety blend (the actual Buffett engine) vs. the parts —
  does the combination diversify, or is one fragment carrying it? Compare against the base keeper book.
- **The leverage fragment, governed.** The float mechanic is the amplifier. Study modest leverage on
  the safe/quality book explicitly, inside the engine's Layer-3 gate and drawdown rails — the opposite
  of [Broad](https://github.com/blaquebaux/broad)'s rejected naive leverage.

## Research — first pass done

Full detail in [`research/README.md`](research/README.md). The scorecard (Alpaca SIP, 2016–2026;
fragments = tradable factor ETFs):

| # | Question | Verdict |
|---|----------|---------|
| 1 | Do the fragments beat the market? | ❌ none did — SPY +0.89 > QUAL +0.84 > MOAT/VLUE +0.79/+0.78 > USMV +0.75; all slightly −alpha |
| 2 | What *is* Berkshire, in fragments? | ✅ **clean win** — BRK.B beta 0.79 (safe), loads +0.55 low-beta / +0.32 value, R² 0.60, residual alpha +2%/yr |
| 3 | Does the blend beat its parts? | ⚠️ diversifies vol not Sharpe — blend +0.83 ≈ best single (QUAL +0.84) < SPY +0.89 |
| 4 | Leverage / cheap float? | ⚠️ scales return+DD together; +3% margin kills it; this decade you'd lever the market, not the safe book |

**The synthesis:** the decomposition is a genuine win — **Berkshire resolves textbook-clean into
Buffett's fragments** (beta 0.79 safe, heaviest on low-beta + value, R² 0.60) with ~2%/yr of residual
alpha that is exactly the part no ETF captures: *selection + cheap insurance float*. But turned forward
as tradable factors, "use the best parts" did **not** beat the market over 2016–2026 — not value, not
quality, not low-vol, not moat, and **not even Buffett himself** (BRK.B +0.73 < SPY +0.89). This was
the mega-cap-growth decade: the cap-weighted index *was* the quality juggernaut, so the tilts were
**defensive beta, not alpha**. Recombination lowers vol but not into excess Sharpe; leverage confirms
the base's law (financing decides, cheap float is the un-buyable moat). The one usable, honest piece is
narrow: **low-vol (USMV) as a drawdown-control lever** (14% vol, −33% DD) — a guardrail, not alpha.
The real Buffett edge is the fragment a retail book *cannot* buy.

## Status
**Research: first pass complete — qualified** (`research/`). The BRK.B decomposition validates the
cheap-safe-quality story cleanly; but as forward tradable fragments none beat the market this decade
(defensive beta, not alpha), and the true moat (cheap float) is un-buyable in a wrapper. Usable piece:
low-vol for defense. No standalone alpha keeper, no live driver; nothing validated to the spine's bar.

## About Blaque Baux

**Blaque Baux** is a quantitative research initiative and a subsidiary of **[Carter Warrens](https://carterwarrens.com)**.
[**BlaqueBaux.com**](https://blaquebaux.com) is the home for the work; the code lives here on GitHub — open to
study, test, and build bespoke strategies on top of.

Anyone can point an AI at a market. The edge is **understanding what the data actually says — and turning it
into something you can act on.** We test relentlessly and put most of it *on the record as rejected, with the
reason*; what survives is built, governed, and validated before it is ever called real. That combination —
honest research, reproducible evidence, and execution you can trust — is why Carter Warrens leads on
**strategy and implementation**, not merely uses the tools everyone now has.

## The Blaque Baux family
This repo is one sleeve of the **Blaque Baux** family — a single governed engine steered in
many directions. The [core repo](https://github.com/blaquebaux/base) is the
base/blueprint and holds the [full family roster](https://github.com/blaquebaux/base#the-blaquebaux-family).

## Layout
```
engine/     the Blaque Baux platform (git submodule -> blaquebaux/base)
research/   four Path-A sketches (fragments, BRK.B decomposition, recombination, leverage) + scorecard
live/       governed live drivers (once a sleeve graduates to paper A/B)
```

## License
[MIT](LICENSE). (c) 2026 Carter Warrens.
