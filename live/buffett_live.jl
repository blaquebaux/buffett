#!/usr/bin/env julia
# ============================================================================
# buffett_live.jl — BLAQUE BAUX BUFFETT live driver (the cheap-safe-quality fragment blend).
#
# Runs on the Blaque Baux ENGINE (engine/ submodule) — same governed order path + Layer-3 safety
# gate as the spine.  data(QUAL, USMV, VLUE, MOAT) -> equal-weight blend -> bonds-regime gross -> orders.
#
# HONEST FRAMING (from research): the fragments are a DEFENSIVE-BETA book, NOT alpha — none beat the
# cap-weighted market this decade, and BRK.B itself lagged SPY. What the blend delivers is lower
# volatility and shallower drawdowns than the market (cheap + safe + quality), i.e. a governed
# DEFENSIVE equity sleeve. The one un-buyable Buffett edge — cheap insurance float — is not here.
# So this driver is a defensive blend, not a market-beater; it graduates to the paper/dry-run path.
#
# The blend is equal-weight across the four tradable fragment ETFs (value/quality/safety/moat) at ~1x
# gross, monthly rebalance. It CONSUMES blaquebaux/bonds' published regime read: when the stock-bond
# correlation is POSITIVE (bond hedge dead — no diversification cushion) it de-risks gross x0.75; when
# NEGATIVE (hedge live) it runs full. Graceful: missing/stale/off -> full gross (only ever reduces risk).
#
# MODES: dry-run by default via the wrapper (BB_DRYRUN=1 -> compute + log, NO venue). Paper: unset
# BB_DRYRUN with paper keys. Real money requires BB_LIVE_CONFIRM=I_UNDERSTAND_THIS_IS_REAL_MONEY.
# Kill switch: ~/.config/blaquebaux/HALT.  Run:  julia --project=engine live/buffett_live.jl
# ============================================================================
using Dates, Printf, Statistics

const REPO   = normpath(joinpath(@__DIR__, ".."))
const ENGINE = joinpath(REPO, "engine")
include(joinpath(ENGINE, "src/module_7_execution/module_7_execution.jl"))
include(joinpath(ENGINE, "src/module_10_feedback/module_10_feedback.jl"))
include(joinpath(ENGINE, "src/module_13_portfolio/module_13_portfolio.jl"))
include(joinpath(ENGINE, "src/module_1_data/equity_panel.jl"))
include(joinpath(ENGINE, "src/module_1_data/alpaca_panel.jl"))
include(joinpath(ENGINE, "src/module_8_governance/safety_gate.jl"))
using .ExecutionLayer, .FeedbackLayer, .PortfolioOptModule, .EquityPanel, .AlpacaPanel, .SafetyGate
include(joinpath(ENGINE, "scripts/live_execution.jl"))

const UNIVERSE = ["QUAL", "USMV", "VLUE", "MOAT"]      # quality / safety(low-beta) / value / moat
const FRAG_W = 1.0 / length(UNIVERSE)                  # equal-weight the fragments (~1x gross)
const LIVE_SENTINEL = "I_UNDERSTAND_THIS_IS_REAL_MONEY"
# --- bonds regime overlay (consumes blaquebaux/bonds' published regime read) -----------------
const REGIME_DERISK   = 0.75
const REGIME_MAXSTALE = Day(7)

_readf(p) = isfile(p) ? (v = tryparse(Float64, strip(read(p, String))); v === nothing ? NaN : v) : NaN
_writef(p, x) = (mkpath(dirname(p)); write(p, string(x)))

"Parse blaquebaux/bonds' published regime file (key=value lines). Returns (; ok, hedge_on, corr, asof)."
function read_bonds_regime(path)
    isfile(path) || return (; ok = false)
    d = Dict{String,String}()
    for ln in eachline(path)
        s = strip(ln); (isempty(s) || startswith(s, "#")) && continue
        kv = split(s, "=", limit = 2); length(kv) == 2 && (d[strip(kv[1])] = strip(kv[2]))
    end
    ho = get(d, "hedge_on", ""); asof = tryparse(Date, get(d, "asof", ""))
    (ho in ("0", "1") && asof !== nothing) || return (; ok = false)
    (; ok = true, hedge_on = ho == "1", corr = tryparse(Float64, get(d, "corr63", "")), asof = asof)
end

"Gross-exposure multiplier from the bonds regime read (graceful: missing/stale/off -> 1.0).
NOTE: default OFF for buffett — validation showed the overlay does NOT earn its place here (the blend
is already defensive via USMV, so de-risking twice costs ~0.03 Sharpe for a small drawdown gain).
Enable with BB_BONDS_OVERLAY=1 if you want the extra drawdown reduction anyway."
function regime_gross_scale(path; derisk = parse(Float64, get(ENV, "BB_REGIME_DERISK", string(REGIME_DERISK))))
    get(ENV, "BB_BONDS_OVERLAY", "0") in ("0", "false", "no") && return (1.0, "bonds overlay OFF by default (validation: doesn't earn its place on the already-defensive blend)")
    r = read_bonds_regime(path)
    r.ok || return (1.0, "no bonds regime signal -> full gross")
    (Dates.today() - r.asof) > REGIME_MAXSTALE && return (1.0, "bonds regime STALE ($(r.asof)) -> full gross")
    c = r.corr === nothing ? NaN : round(r.corr, digits = 2)
    r.hedge_on ? (1.0,    "bond hedge LIVE (neg-corr $c) -> full gross") :
                 (derisk, "bond hedge DEAD (pos-corr $c) -> de-risk x$derisk")
end

"Equal-weight cheap-safe-quality fragment blend, scaled by the bonds regime overlay."
function buffett_target(panel, cap; gross_scale = 1.0)
    syms = panel.symbols
    idx(s) = findfirst(==(s), syms); px(s) = panel.prices[idx(s)]
    net = Dict(s => FRAG_W * gross_scale for s in UNIVERSE)
    price = Dict(s => px(s) for s in UNIVERSE)
    targets = Dict(s => round(Float64, net[s] * cap / price[s]) for s in UNIVERSE)
    (targets = targets, prices = price, net = net)
end

function main(; capital = nothing, pool = "us", limits::SafetyLimits = SafetyLimits(),
              db_path     = get(ENV, "BB_LEDGER_PATH", joinpath(REPO, "alpaca_ledger_buffett.sqlite")),
              audit_path  = get(ENV, "BB_AUDIT_PATH",  joinpath(REPO, "alpaca_audit_buffett.jsonl")),
              hwm_path    = get(ENV, "BB_HWM_PATH",    joinpath(homedir(), ".config", "blaquebaux", "equity_hwm_buffett.txt")),
              equity_path = get(ENV, "BB_EQUITY_PATH", joinpath(homedir(), ".config", "blaquebaux", "equity_last_buffett.txt")),
              regime_path = get(ENV, "BB_REGIME_PATH", joinpath(homedir(), ".config", "blaquebaux", "bonds_regime.txt")))
    (get(ENV, "ALPACA_KEY_ID", "") == "" || get(ENV, "ALPACA_SECRET_KEY", "") == "") &&
        error("Set ALPACA_KEY_ID and ALPACA_SECRET_KEY (read-only bars are needed even in dry-run).")
    dryrun = get(ENV, "BB_DRYRUN", "") in ("1", "true", "yes")

    if dryrun
        panel = panel_at(AlpacaPanelProvider(UNIVERSE; lookback = 120))
        rscale, rnote = regime_gross_scale(regime_path)
        bk = buffett_target(panel, capital === nothing ? 100_000.0 : capital; gross_scale = rscale)
        @info "BUFFETT dry run" asof=panel.asof
        println("\n  bonds regime -> ", rnote)
        println("  cheap-safe-quality blend (gross ", @sprintf("%.0f%%", 100sum(values(bk.net))), "):")
        for (s, w) in sort(collect(bk.net), by = x -> -x[2])
            @printf("    %-4s %5.1f%%  -> %d sh @ \$%.2f\n", s, 100w, Int(get(bk.targets, s, 0.0)), get(bk.prices, s, NaN))
        end
        ok, reasons = preflight(; account_status = "ACTIVE", equity = 100_000.0, hwm = 100_000.0,
            last_equity = 100_000.0, buying_power = 100_000.0, data_fresh = (Dates.today() - panel.asof) <= Day(5),
            targets = bk.targets, prices = bk.prices, limits = limits)
        println("\n  DRY RUN — no venue, no orders. Gate: ", ok ? "PASS" : "ABORT: " * join(reasons, "; "))
        return ok ? :dryrun_ok : :dryrun_gate_abort
    end

    live = get(ENV, "BB_LIVE_CONFIRM", "") == LIVE_SENTINEL; paper = !live
    mode = live ? "*** LIVE REAL MONEY ***" : "paper"
    @info "buffett_live starting" mode
    live && alert("BUFFETT LIVE REAL-MONEY mode engaged"; level = :critical)
    venue = AlpacaVenue(AlpacaConfig(; paper = paper))
    built = build_live_controller(; venue = venue, ledger_config = LedgerConfig(; db_path = db_path), audit_path = audit_path)
    ctrl, ledger = built.ctrl, built.ledger
    try
        connect!(venue) || (alert("ABORT [$mode]: Alpaca connect failed (buffett)"; level = :critical); return :connect_failed)
        acct = account_info(venue)
        acct === nothing && (alert("ABORT [$mode]: could not read account (buffett)"; level = :critical); return :no_account)
        cap = capital === nothing ? acct.equity : capital
        hwm = max(load_hwm(hwm_path), acct.equity); last_eq = _readf(equity_path)
        panel = panel_at(AlpacaPanelProvider(UNIVERSE; lookback = 120)); fresh = (Dates.today() - panel.asof) <= Day(5)
        rscale, rnote = regime_gross_scale(regime_path); @info "bonds regime overlay" note=rnote
        bk = buffett_target(panel, cap; gross_scale = rscale)
        ok, reasons = preflight(; account_status = acct.status, trading_blocked = acct.trading_blocked,
            account_blocked = acct.account_blocked, equity = acct.equity, hwm = hwm, last_equity = last_eq,
            buying_power = acct.buying_power, data_fresh = fresh, targets = bk.targets, prices = bk.prices, limits = limits)
        save_hwm(hwm, hwm_path); _writef(equity_path, acct.equity)
        if !ok
            msg = "SAFETY ABORT [$mode] (buffett): " * join(reasons, "; "); @error msg
            halt!(ctrl, "safety gate"); alert(msg; level = :critical); return :aborted
        end
        reset_daily!(ctrl)
        set_pool_budget!(ctrl, pool, limits.max_gross_leverage * acct.equity)
        set_pool_loss_limit!(ctrl, pool, limits.max_daily_loss)
        set_pool_staleness!(ctrl, pool, Day(5)); feed_staleness!(ctrl, pool; stale = !fresh)
        isfinite(last_eq) && update_pnl!(ctrl, pool, acct.equity - last_eq)
        ncanc = cancel_all_open!(venue); ncanc > 0 && sleep(2)
        for (sym, qty) in positions(venue, ctrl.account); apply_fill!(ctrl, sym, qty); end
        res = execute_rebalance!(ctrl, ledger; targets = bk.targets, prices = bk.prices,
            signal_id = "buffett", regime = "cheap-safe-quality-regx$(round(rscale, digits=2))",
            solve_id = Dates.format(panel.asof, "yyyymmdd"), pool_id = pool, settle_secs = 20)
        !res.reconciled && (alert("RECONCILE FAILED [$mode] (buffett) — halting"; level = :critical); halt!(ctrl, "reconcile mismatch"))
        summary = "[$mode] buffett defensive blend (gross $(round(Int, 100sum(values(bk.net))))%); orders=$(length(res.acks)) fills=$(length(res.fills)) reconciled=$(res.reconciled) equity=$(round(Int, acct.equity))"
        @info "buffett_live complete" summary; alert(summary; level = :info)
        return res.reconciled ? :ok : :reconcile_failed
    finally
        disconnect!(venue); close_ledger(ledger)
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
