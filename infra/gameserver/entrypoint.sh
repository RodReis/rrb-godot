#!/bin/sh
set -e

if [ -n "$NETEM_DELAY_MS" ]; then
  tc qdisc add dev eth0 root netem \
    delay "${NETEM_DELAY_MS}ms" "${NETEM_JITTER_MS:-0}ms" \
    loss "${NETEM_LOSS_PCT:-0}%"
  echo "[netem] delay=${NETEM_DELAY_MS}ms jitter=${NETEM_JITTER_MS:-0}ms loss=${NETEM_LOSS_PCT:-0}%"
fi

exec godot --headless --path /game -- --server "--port=${PORT:-7000}"
