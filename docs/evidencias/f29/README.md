# F29 / SPEC-029 — evidência de aceite

Telemetria de partida (Game → backend) e web-admin de KPIs. Branch `feat/SPEC-029-telemetria-web-admin`, issue #253.

## 1. Soak (aceite 4)

`.\tools\soak.ps1 -Count 50 -Parallel 8` com o código final do Game: **50/50 partidas terminadas, 50 com vencedor, 0 falhas**, duração de jogo min 348 s, média 395 s, máx 502 s (limite 600 s), todas por `kill_goal`. O soak é bot × bot sem cliente: não gera `teleportCount` (só o cliente conta). O zero do cenário A está na seção 2.

## 2. Calibração do teleporte (aceite 5)

`.\tools\net-measure.ps1` (servidor em Docker com `tc netem` + 2 clientes reais jogados pelo bot, 10 min), cenários do ADR-0001. Métrica: `[probe] salto maximo` = maior deslocamento visual somado numa janela de 50 ms, além do que a velocidade explica, em quadro não isento. Limite avaliado: `teleport_threshold_u = 1.0`.

| Cenário | Cliente | Salto máx. (u) | Teleportes | `Reference tick missing` |
|---|---|---|---|---|
| A — rede limpa | 1 | 0,07 | **0** | 0 |
| A — rede limpa | 2 | 0,23 | **0** | 0 |
| B — 100 ms, 2 % perda | 1 | 0,17 | 0 | 2 |
| B — 100 ms, 2 % perda | 2 | 0,57 | 0 | 0 |
| C — 200 ms, jitter 30 ms, 5 % perda | 1 | 1,99 | 4 | 110 |
| C — 200 ms, jitter 30 ms, 5 % perda | 2 | 0,23 | 0 | 202 |

- **A deu zero**, como o aceite pede. Em A e B o maior salto (0,57 u) fica abaixo do limite com folga, então **1,0 u foi mantido**; o `.tres` não mudou.
- Em C o cliente 1 passou do limite (1,99 u, 4 contagens), com a rede degradada. Não separei, nesses 4 eventos, correção de rede de falso positivo; o critério de aceite é o A.
- O cliente 2 de C teve mais descartes de estado (202) e nenhum salto contado: o descarte congela o remoto em vez de teletransportá-lo no cliente dele.
- `teleport_cooldown_s = 0.5` não foi calibrado separadamente (proposta do Cowork); ficou como está.

Medição feita com a VM do Docker liberada (containers de outros projetos parados durante a medição, por decisão do PI, e religados no fim).

## 3. `ERROR` de `tree_exiting` no servidor

Os logs do servidor em Docker trazem 2 linhas `ERROR: Attempt to disconnect a nonexistent connection ... Signal: 'tree_exiting'` ao encerrar a partida. A mesma partida curta (`-BothBots -StartTime 570`) na `origin/main` sem esta fatia dá as mesmas 2 linhas: é ruído anterior ao F29 (netfox ao liberar heróis), não uma regressão.

## 4. O que esta evidência não cobre (pendente)

- **Partida real no VPS** (`api.lootstart.cloud`) chegando ao web-admin com ping, duração, nível F1 e teleportes, e o CSV baixado batendo com a tela (aceite 6): depende de o PI subir esta versão no VPS e de criar a conta admin (`ADMIN_EMAILS`, conta criada **antes**).
- **Verificação visual do web-admin pelo PI** (aceite 7).
- O ENet `PEER_ROUND_TRIP_TIME` no servidor dedicado só se confirma com o ping preenchido nessa partida real.

## 5. Capturas do web-admin

`admin-login.png`, `admin-kpis.png`, `admin-matches.png`: visual do `admin/` com **dados de teste** de uma API falsa (não são dados de partida real).
