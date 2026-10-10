#!/bin/sh
set -e

# NETEM_DELAY_MS e o RTT alvo: metade na saida (eth0) e metade na entrada (ifb0).
# Atraso so numa direcao desalinha o relogio do netfox, que supoe ida e volta
# simetricas (medido no gate do M0, ADR-0001).
if [ -n "$NETEM_DELAY_MS" ]; then
  half_delay=$((NETEM_DELAY_MS / 2))
  half_jitter=$((${NETEM_JITTER_MS:-0} / 2))
  loss="${NETEM_LOSS_PCT:-0}"
  ip link add ifb0 type ifb
  ip link set ifb0 up
  tc qdisc add dev eth0 handle ffff: ingress
  tc filter add dev eth0 parent ffff: matchall action mirred egress redirect dev ifb0
  tc qdisc add dev ifb0 root netem delay "${half_delay}ms" "${half_jitter}ms" loss "${loss}%"
  tc qdisc add dev eth0 root netem delay "${half_delay}ms" "${half_jitter}ms" loss "${loss}%"
  echo "[netem] rtt=${NETEM_DELAY_MS}ms (${half_delay}ms por direcao) jitter=${NETEM_JITTER_MS:-0}ms loss=${loss}% por direcao"
fi

# GAME_ARGS: argumentos extras do jogo, separados por espaco (ex.: "--probe --seed=20").
# shellcheck disable=SC2086
exec godot --headless --path /game -- --server "--port=${PORT:-7000}" ${GAME_ARGS:-}
