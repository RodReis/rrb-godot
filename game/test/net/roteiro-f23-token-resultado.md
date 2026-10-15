# Roteiro F23 — token de partida, resultado e códigos de saída (SPEC-023, #79)

Servidor dedicado + clientes headless contra o backend local (sem Docker: `POOL_SIZE=0`). A partida é criada direto no banco com **um token por jogador**, como o orquestrador faria.

## Preparo

```powershell
# 1. banco descartável e backend (porta 3100); os segredos são só de teste local
docker exec infra-postgres-1 psql -U rrb -d postgres -c "CREATE DATABASE rrb_f23"
$env:DATABASE_URL = 'postgres://rrb:rrb@localhost:5432/rrb_f23'
$env:JWT_SECRET = 'f23-jwt-secret-local-apenas-teste-0123456789'
$env:INTERNAL_SECRET = 'f23-interno-secret-local-apenas-teste-9876543210'
$env:PORT = '3100'; $env:POOL_SIZE = '0'; $env:POOL_MAX = '1'; $env:SWEEP_INTERVAL_MS = '0'; $env:LOG_LEVEL = 'warn'
pnpm -C backend build; node backend/dist/src/main.js          # em background

# 2. uma partida nova a cada cenário (o token vale 120 s)
node game/test/net/f23-setup-match.js $env:TEMP\f23-match.json http://localhost:3100

# 3. cenário
.\game\test\net\f23-net-test.ps1 -MatchFile $env:TEMP\f23-match.json -Out $env:TEMP\f23-run `
    -BackendUrl http://localhost:3100 -Port 7101
```

Quem sobe tudo é o Code, em background (CLAUDE.md). Os tokens ficam no JSON do preparo: não commitar nem colar em log.

## Cenários e resultado esperado

| # | Cenário | Como | Esperado |
|---|---|---|---|
| A | Token válido, partida inteira | passo 3 sem mais nada | servidor sai `0`; no banco `matches.status=finished`, `end_reason=collapse_hp`, `match_players` com o herói e as estatísticas **da conta dona de cada token** (vencedor = conta do peer vencedor); `last_heartbeat_at` avança de 10 em 10 s |
| B1 | Token lixo | `-TokenA 'lixo' -NoClientB -ServerWaitSeconds 12` | cliente sai `2`; servidor imprime `[auth] peer N recusado (denied)` e continua de pé |
| B2 | Token expirado (partida antiga, > 2 min) | `-NoClientB -ServerWaitSeconds 12` com o JSON de uma partida antiga | cliente sai `2` (`TOKEN_EXPIRED` no backend) |
| B3 | Sem token | `-TokenA '' -NoClientB -ServerWaitSeconds 12` | cliente sai `2` |
| C | Backend cai no meio da partida | cenário A e `taskkill` do backend ~20 s depois | servidor avisa do heartbeat (uma vez), tenta `result` 3× (1 s, 2 s), grava `%APPDATA%\rrb-moba\results\<match_id>.json` e sai `3` |
| D | O 2º jogador nunca chega | `-NoClientB -ServerWaitSeconds 160` | aos 120 s o lobby estoura: `abandoned`; resultado sem jogadores; servidor sai `0`; no banco `finished` / `abandoned` |

Obs.: com o fim da partida o cliente mostra a tela de fim e espera o botão "Voltar"; "rodando" no cliente depois que o servidor saiu é normal. Para recusa (B), o código do **cliente** é o que vale.

## Execução — 2026-10-15 (Code, Windows, backend e servidor locais, clientes headless)

| Cenário | Resultado |
|---|---|
| A | OK — servidor `0`; `finished`/`collapse_hp`, duração 600 s; ranger e cavaleiro gravados para as contas certas (peer → conta conferido com o log dos clientes); `last_heartbeat_at` 30 s depois de `started_at` |
| B1 | OK — `2` (a 1ª execução deu `4`: recusa imediata largava o peer antes da resposta sair; corrigido com 0,25 s de espera em `PeerAuth`) |
| B2 | OK — `2` |
| B3 | OK — `2` (cliente sem token manda o marcador `-`: o auth do SceneMultiplayer recusa pacote vazio e a 1ª tentativa saiu com `4`) |
| C | OK — servidor `3`; arquivo gravado com o corpo do `MatchResult` |
| D | OK — aos 120 s `LOBBY_WAIT -> ENDED (abandoned)`; resultado sem jogadores (o único peer não escolheu herói); servidor `0`; banco `finished` / `abandoned` / 0 s |

Nenhum token nem o segredo interno aparece nos logs do servidor nem dos clientes.
