#!/bin/bash
# run_buffett_daily.sh — buffett defensive cheap-safe-quality blend (Blaque Baux). DRY-RUN by default
# (logs the target, places nothing) using the shared read-only data keys; graduates to PAPER once
# ~/.config/blaquebaux/alpaca_buffett.env exists (that account's own keys). One-time:
# julia --project=engine -e 'using Pkg; Pkg.instantiate()'.  Manual dry test: BB_DRYRUN=1 bash live/run_buffett_daily.sh
# Bonds-regime overlay is OFF by default here (validation: doesn't earn its place on the already-defensive
# blend); enable with BB_BONDS_OVERLAY=1 if you want the extra drawdown reduction.
set -uo pipefail
REPO="/Users/malcolmx/blaquebaux-buffett"; ENGINE="$REPO/engine"; JULIA="/Users/malcolmx/.juliaup/bin/julia"
DATAENV="$HOME/.config/blaquebaux/alpaca.env"; SLEEVEENV="$HOME/.config/blaquebaux/alpaca_buffett.env"
LOGDIR="$REPO/logs"; mkdir -p "$LOGDIR"; LOG="$LOGDIR/buffett_$(TZ=America/New_York date +%Y%m%d).log"
exec >> "$LOG" 2>&1
echo "======== $(TZ=America/New_York date '+%F %T %Z') buffett daily run ========"
export BB_LEDGER_PATH="$REPO/alpaca_ledger_buffett.sqlite" BB_AUDIT_PATH="$REPO/alpaca_audit_buffett.jsonl"
export BB_HWM_PATH="$HOME/.config/blaquebaux/equity_hwm_buffett.txt" BB_EQUITY_PATH="$HOME/.config/blaquebaux/equity_last_buffett.txt"
export BB_REGIME_PATH="$HOME/.config/blaquebaux/bonds_regime.txt"   # read only if BB_BONDS_OVERLAY=1
if [ -f "$SLEEVEENV" ]; then set -a; source "$SLEEVEENV"; set +a
else [ -f "$DATAENV" ] && { set -a; source "$DATAENV"; set +a; }; export BB_DRYRUN=1; fi
if [ -z "${ALPACA_KEY_ID:-}" ] || [ -z "${ALPACA_SECRET_KEY:-}" ]; then echo "no ALPACA keys — skipping"; exit 0; fi
MODE=$([ "${BB_DRYRUN:-}" = "1" ] && echo dryrun || echo paper); echo "mode=$MODE"
if [ "$MODE" = "paper" ]; then
  CLOCK=$(curl -s --max-time 15 -H "APCA-API-KEY-ID: $ALPACA_KEY_ID" -H "APCA-API-SECRET-KEY: $ALPACA_SECRET_KEY" https://paper-api.alpaca.markets/v2/clock)
  IS_OPEN=$(echo "$CLOCK" | grep -Eo '"is_open":(true|false)' | grep -Eo 'true|false' | head -1)
  NEXT_OPEN=$(echo "$CLOCK" | grep -o '"next_open":"[^"]*"' | grep -Eo '[0-9]{4}-[0-9]{2}-[0-9]{2}' | head -1)
  ET_TODAY=$(TZ=America/New_York date +%F)
  if { [ -n "$IS_OPEN" ] || [ -n "$NEXT_OPEN" ]; } && [ "$IS_OPEN" != "true" ] && [ "$NEXT_OPEN" != "$ET_TODAY" ]; then echo "not a trading day — skipping"; exit 0; fi
  ORDERS_TODAY=$(curl -s --max-time 15 -H "APCA-API-KEY-ID: $ALPACA_KEY_ID" -H "APCA-API-SECRET-KEY: $ALPACA_SECRET_KEY" "https://paper-api.alpaca.markets/v2/orders?status=all&limit=10&after=${ET_TODAY}T00:00:00Z" | grep -o '"id"' | wc -l | tr -d ' ')
  [ "${ORDERS_TODAY:-0}" -gt 0 ] && { echo "already placed today — skipping (catch-up no-op)"; exit 0; }
fi
cd "$REPO" || exit 1
"$JULIA" --project="$ENGINE" "$REPO/live/buffett_live.jl"; RC=$?
echo "======== done rc=$RC $(TZ=America/New_York date '+%T %Z') ========"; exit $RC
