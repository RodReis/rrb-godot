# rrb-godot

MOBA de 2 tempos em **Godot 4.7.2** (3D, Forward+), multiplayer com servidor autoritativo.
PRD: `docs/prd/PRD.md`. Marco atual: **M0 — spike de netcode**.

## Estrutura

```
game/      projeto Godot (cliente + servidor dedicado)
infra/     Docker do game server (com simulação de latência via netem)
tools/     scripts PowerShell (setup, testes, rodar servidor/clientes)
docs/      PRD, planos, ADRs
```

## Comandos (PowerShell, na raiz)

| O quê | Comando |
|---|---|
| Setup Godot + godot-mcp | `powershell -ExecutionPolicy Bypass -File tools\setup-godot-mcp.ps1` |
| Testes unitários (GUT) | `.\tools\test.ps1` |
| Servidor local (sem Docker) | `.\tools\run-server.ps1` |
| Servidor Docker | `docker compose -f infra/docker-compose.yml up --build` |
| Servidor Docker com 100 ms + 2% perda | `$env:NETEM_DELAY_MS=100; $env:NETEM_LOSS_PCT=2; docker compose -f infra/docker-compose.yml up --build` |
| 2 clientes (2º em autopilot) | `.\tools\run-clients.ps1 -Autopilot` |

Controles: WASD move, mouse mira, botão esquerdo ataca.
Argumentos do jogo (depois de `--`): `--server`, `--port=7000`, `--connect=host:porta`, `--autopilot`.
