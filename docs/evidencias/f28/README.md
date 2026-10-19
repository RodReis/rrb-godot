# F28 — Deploy no VPS: evidência do aceite (2026-10-19)

Ambiente: VPS Hostinger KVM 2 (2 vCPU, 7,8 GB, Ubuntu 24.04, **São Paulo**) com Coolify, domínio
`api.lootstart.cloud`, commit `4a94911` da `main`. Executado pelo Code.

## O que foi exercitado

ZIP gerado por `tools/build-package.ps1 -ApiUrl https://api.lootstart.cloud` (276 MB: `launcher.exe`,
`launcher.pck`, `game/game.exe`, `game/game.pck`, `LEIA-ME.txt`), extraído numa pasta limpa fora do
repositório. Dois Launchers (`tools/ui/drive_launcher.gd`, cada um com a própria conta) fizeram o fluxo
inteiro contra o backend e o game server **do VPS**, abrindo o `game.exe` **do ZIP**:

cadastro → apelido (F35) → lobby → fila → pareados → Game aberto → conectou por UDP ao VPS → "Encerrar
jogo" → volta ao lobby. Os dois terminaram com `fim (0): ok`.

Linha do tempo no servidor (logs do backend, UTC, tempo de resposta entre parênteses):

| Hora | Evento |
|---|---|
| 19:51:34 | A: `POST /queue` 201 (10 ms) |
| 19:51:36 | B: `POST /queue` 201 (14 ms) — pareia no ato; o polling de 2 s do Launcher vê `matched` às 19:51:38 |
| 19:51:46 | game server: `POST /internal/matches/<id>/validate` 200 — **1º cliente conectou por UDP** e o token foi validado |
| 19:51:52 | `validate` 200 — **2º cliente** |
| 19:51:56 → | `heartbeat` 204 a cada 10 s (3–11 ms) |

## Medições

| O quê | Valor |
|---|---|
| Ping ao VPS (ICMP, 10 pacotes) | **16 ms** médio (15–19) |
| HTTPS ao backend, conexão nova (curl, 5 amostras) | 62–97 ms; a 1ª, fria, 482 ms |
| HTTPS reaproveitando a conexão | 16 ms |
| Formação de partida (2º jogador entra → pareado) | imediata no servidor; o Launcher vê em ≤ 2 s (polling) |
| Do pareado ao 1º cliente validado no game server | 8 s (abrir o `game.exe`, carregar e conectar) |
| Smoke pela API (2 contas, 2 `POST /queue`, 1 polling) | `matched` em 119 ms, `host` `187.127.63.136`, `port` 7000 |

O PRD pede ≤ 80 ms para jogadores no Brasil: o RTT UDP esperado é o do ICMP (16 ms).

**Atenção — o número do Launcher não é o ping.** O rodapé e o console da fila mostram
"SERVIDOR ONLINE **229 ms**" (capturas abaixo). O Launcher mede um `GET /health` com **conexão nova**
(um `HTTPRequest` por chamada, DNS + TCP + TLS cada vez): 229 ms contra 16 ms de RTT. A UI superestima o
ping em ~14×. Está de acordo com o desenho do F25 (V-08a, "ping HTTP"), mas é enganoso para o jogador.

## Descobertas e correções neste PR

1. **Rede dos game servers** (PR #224, já na `main`): o Coolify ignora o `name:` da rede do compose e a
   chama pelo UUID do recurso; `GAMESERVER_NETWORK` virou variável.
2. **Logs dos game servers vazios** (PRD §8.5): com o stdout num pipe, o Godot só descarrega a cada ~4 KB;
   `docker logs` mostrava só stderr (2 linhas) e nenhum `[server]`/`[net]`/`[spawn]`. Medido no VPS com a
   mesma imagem: 2 linhas sem `stdbuf -oL`, 8 com. `infra/gameserver/entrypoint.sh` agora usa `stdbuf -oL`.
3. **Driver do Launcher** (`tools/ui/drive_launcher.gd`): esperava o lobby por 600 **quadros**; sem vsync
   isso são frações de segundo e estourava contra um backend remoto. Agora espera por tempo (15 s) e trata
   a tela de apelido do F35.

## Não coberto (`not_run`)

- `launcher.exe` **do ZIP** não foi executado: só o `game.exe` do ZIP. O fluxo de telas foi provado com o
  Launcher do projeto passando `--api=https://api.lootstart.cloud`; que o executável do ZIP use a URL
  embutida (`build_config.cfg` no `.pck`) **não foi verificado em execução**. Isso, a verificação visual e
  o Release com SmartScreen ficam com o PI.
- GitHub Release com tag `v0.x`: não publicado. A variável de repositório `RRB_API_URL` não pôde ser criada
  pelo `gh` (`HTTP 403`, token sem permissão de Actions variables) e o ensaio do `release.yml` falhou nesse
  passo. O ZIP foi gerado localmente.
- UDP medida por tráfego real de jogo curto (clientes saíram em ~45 s); sem soak, sem perda/jitter.

## Arquivos

- `launcher-a-01-lobby.webp`, `-02-procurando.webp`, `-03-partida.webp`, `-04-volta.webp`: Launcher A em
  cada etapa (capturas do próprio driver).

## Release v0.1.0 (2026-10-19)

Tag anotada `v0.1.0` em `25e2cb3` (CI da `main` verde); `release.yml` publicou o pré-lançamento
<https://github.com/RodReis/rrb-godot/releases/tag/v0.1.0> com `rrb-arena-v0.1.0-win64.zip` (289 MB).

Verificado com o ZIP **baixado do Release** numa pasta limpa fora do repositório:

- `launcher.exe` sem argumentos: o backend do VPS recebeu 3 `GET /health` com o User-Agent do Godot em 14 s (a URL
  embutida no pacote funciona; o chip de ping mostra o valor real, 18 ms).
- 2 Launchers (cadastro → fila → partida) com o `game.exe` do Release: os dois jogos abriram, conectaram por UDP ao
  servidor do VPS (2 `validate` + 5 heartbeats no backend) e voltaram ao lobby (`fim (0): ok`).

Redeploy final em `a909991`: logs dos game servers legíveis, F79 e F80 no servidor, teste de abandono real
(`docs/evidencias/f80/`). Contas de teste removidas do banco de produção (ficou só a do PI).
