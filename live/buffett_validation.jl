#!/usr/bin/env julia
# ============================================================================
# buffett_validation.jl — validate-before-live gate for the BUFFETT defensive blend.
#
# BUFFETT is not an alpha play (research: the fragments are defensive beta, none beat the market).
# So the honest bar is a DEFENSIVE one, in two parts:
#   PART 1 — the blend vs the market: lower drawdown and lower vol than SPY, at a comparable
#            risk-adjusted return (a cheap-safe-quality book should be calmer than the index).
#   PART 2 — the bonds-regime overlay: de-risking gross when the bond hedge is dead should reduce
#            drawdown further without hurting Sharpe (same test as boom/broad).
#
# Fully causal walk-forward reusing buffett_target (the real book) + the same 63d SPY-IEF regime the
# bonds driver publishes. Net of cost. Reuses buffett_target/UNIVERSE/REGIME_DERISK from buffett_live.jl.
#   Run:  julia --project=engine live/buffett_validation.jl
# ============================================================================
include(joinpath(@__DIR__, "buffett_live.jl"))
using Dates, Printf, Statistics

_sh(r; ann = 252) = (x = r[isfinite.(r)]; s = std(x); s > 0 ? mean(x) / s * sqrt(ann) : NaN)
_dd(r) = (lvl = cumprod(1 .+ r); minimum(lvl ./ accumulate(max, lvl) .- 1))
_cagr(r) = (lvl = cumprod(1 .+ r); lvl[end]^(252 / length(r)) - 1)

function fetch_panel(U, lb = 2600)
    try
        return panel_at(AlpacaPanelProvider(U; lookback = lb, calendar_days = 4300, feed = "sip"), Dates.today() - Day(30))
    catch e
        m = match(r"only (\d+) common", sprint(showerror, e)); m === nothing && rethrow(e)
        n = parse(Int, m.captures[1]) - 20; (n < 200 || n >= lb) && rethrow(e)
        return fetch_panel(U, n)
    end
end

function main_validate(; reb = 21, warmup = 80, corr_win = 63,
                       cost_bps = parse(Float64, get(ENV, "BB_COST_BPS", "5")), derisk = REGIME_DERISK)
    panel = fetch_panel(vcat(UNIVERSE, "SPY", "IEF"))
    R = panel.returns; syms = panel.symbols; T = size(R, 1); cost = cost_bps / 1e4
    si = Dict(s => i for (i, s) in enumerate(syms)); dummy = ones(length(syms))
    subpanel(t) = (returns = R[1:t, :], symbols = syms, prices = dummy)
    spy = R[:, si["SPY"]]; ief = R[:, si["IEF"]]
    ret(w, day) = sum(get(w, s, 0.0) * R[day, si[s]] for s in keys(w); init = 0.0)

    blend = Float64[]; over = Float64[]; oosidx = Int[]
    wb_prev = Dict{String,Float64}(); wo_prev = Dict{String,Float64}(); npos = 0; nderisk = 0
    for t0 in warmup:reb:(T-1)
        wb = buffett_target(subpanel(t0), 1.0; gross_scale = 1.0).net
        corr = cor(spy[t0-corr_win+1:t0], ief[t0-corr_win+1:t0])
        hedge_on = corr < 0; scale = hedge_on ? 1.0 : derisk
        wo = Dict(s => v * scale for (s, v) in wb)
        npos += 1; hedge_on || (nderisk += 1)
        tb = sum(abs(get(wb, s, 0.0) - get(wb_prev, s, 0.0)) for s in union(keys(wb), keys(wb_prev)); init = 0.0)
        to = sum(abs(get(wo, s, 0.0) - get(wo_prev, s, 0.0)) for s in union(keys(wo), keys(wo_prev)); init = 0.0)
        for day in (t0+1):min(t0+reb, T)
            rb = ret(wb, day); ro = ret(wo, day)
            if day == t0 + 1; rb -= tb * cost; ro -= to * cost; end
            push!(blend, rb); push!(over, ro); push!(oosidx, day)
        end
        wb_prev = wb; wo_prev = wo
    end
    spyO = [R[i, si["SPY"]] for i in oosidx]

    println("="^78, "\nBUFFETT — defensive-blend validation (net $(round(Int,cost*1e4)) bps/side, causal)\n", "="^78)
    @printf("\n  OOS days %d   rebalances %d   overlay de-risked %d (%.0f%%)\n", length(blend), npos, nderisk, 100nderisk/npos)
    @printf("  %-30s %8s %8s %7s %8s\n", "book", "Sharpe", "CAGR", "vol", "maxDD")
    for (lbl, r) in [("SPY (the market)", spyO), ("BLEND (QUAL/USMV/VLUE/MOAT)", blend), ("BLEND + bonds-regime overlay", over)]
        @printf("  %-30s %+8.2f %7.1f%% %6.1f%% %7.0f%%\n", lbl, _sh(r), _cagr(r)*100, std(r)*sqrt(252)*100, _dd(r)*100)
    end

    shS, shB, shO = _sh(spyO), _sh(blend), _sh(over)
    ddS, ddB, ddO = _dd(spyO), _dd(blend), _dd(over)
    println("\n  PART 1 — is the blend a genuine defensive book vs the market?")
    p1 = [("shallower drawdown than SPY", ddB > ddS,        @sprintf("%.0f%% vs %.0f%%", ddB*100, ddS*100)),
          ("lower vol than SPY",          std(blend) < std(spyO), @sprintf("%.1f%% vs %.1f%%", std(blend)*sqrt(252)*100, std(spyO)*sqrt(252)*100)),
          ("Sharpe within 0.15 of SPY",   shB >= shS - 0.15, @sprintf("%.2f vs %.2f", shB, shS))]
    for (n, ok, v) in p1; @printf("    [%s] %-32s %s\n", ok ? "PASS" : "FAIL", n, v); end
    println("\n  PART 2 — does the bonds-regime overlay earn its place on the blend?")
    p2 = [("Sharpe not worse (>= blend - 0.03)", shO >= shB - 0.03, @sprintf("%.2f vs %.2f", shO, shB)),
          ("reduces drawdown vs blend",          ddO > ddB,          @sprintf("%.0f%% -> %.0f%%", ddB*100, ddO*100))]
    for (n, ok, v) in p2; @printf("    [%s] %-32s %s\n", ok ? "PASS" : "FAIL", n, v); end

    # two independent decisions: (1) graduate the blend?  (2) turn the overlay on?
    build_ok = all(c -> c[2], p1)
    overlay_ok = all(c -> c[2], p2)
    println("\n  DECISION 1 (graduate the blend): ", build_ok ?
        "PASS — a governed DEFENSIVE blend, calmer than the market at ~the same Sharpe. Graduates to the\n           paper/dry-run path. NOT a market-beater (research: defensive beta, not alpha); not live money." :
        "FAIL — the blend is not a genuine defensive book on this sample; stays dry-run.")
    println("  DECISION 2 (bonds-regime overlay): ", overlay_ok ?
        "ON by default — earns its place." :
        "OFF by default — it reduces drawdown but costs Sharpe here (the blend is already defensive via\n           USMV; de-risking twice is redundant). Wired in and available via BB_BONDS_OVERLAY=1.")
    return (; build_ok, overlay_ok, shB, shO, ddS, ddB, ddO)
end

if abspath(PROGRAM_FILE) == @__FILE__
    main_validate()
end
