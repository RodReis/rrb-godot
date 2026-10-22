# rrb-godot — Loot Start

MOBA 3D de 2 tempos (preparação de 5 min → confronto com zona que fecha), 1x1, em **Godot 4.7.2** (Forward+), com **servidor autoritativo** e 11 heróis jogáveis.
Escopo: `docs/prd/PRD.md`. Andamento: `docs/STATUS.md`. Decisões: `docs/DECISIONS.md`.

São dois programas independentes que se falam por processo e argumentos (`docs/ARCHITECTURE-LAUNCHER.md` §5):

- **Launcher** — fora da partida: login e cadastro, lobby, fila, histórico, bestiário, forja, arena e mapa, configurações.
- **Game** — a partida: seleção de heróis, jogo e tela de fim. O Launcher é quem o abre.

---

## Para jogar (instalação do pacote)

> **Estado:** o instalador sai a cada Release (F83, #242) em https://lootstart.cloud e depende do servidor no VPS. Enquanto não houver Release publicado, use a seção "Para desenvolver".

**Requisitos:** Windows 64 bits, placa de vídeo com Vulkan (o Game só roda no renderer Forward+), internet.

1. Baixe o instalador `LootStart-Setup.exe` em https://lootstart.cloud (botão de download).
2. Abra o instalador. **Aviso do Windows (SmartScreen):** sem assinatura de código, aparece "O Windows protegeu seu computador"; clique em **Mais informações** e depois em **Executar assim mesmo**. O jogo instala em `%LOCALAPPDATA%\Programs\Loot Start`, sem pedir administrador, com atalhos no Menu Iniciar e na Área de Trabalho; desinstala por "Aplicativos instalados".
3. Abra o **Loot Start**. Versão nova: o Launcher avisa ao abrir e se atualiza sozinho (obrigatório para a fila online; o treino segue liberado).
5. **Crie sua conta** (aba "Criar conta"): e-mail e senha com **mínimo de 8 caracteres, ao menos uma letra e um número**. Não há recuperação de senha nem verificação de e-mail.
6. **Defina o nickname** (obrigatório no 1º login): 3–16 caracteres `A–Z a–z 0–9 _`, único sem diferenciar maiúsculas. Ele aparece com `#` na frente. Você pode escolher um avatar (predefinido ou PNG/JPG até 1 MB, que fica só no seu computador).
7. No lobby, clique em **BUSCAR PARTIDA 1V1**. Quando o oponente aparece, o Launcher abre o Game sozinho. Ao fim da partida o Game fecha (sozinho em 15 s, ou em "Voltar ao lobby") e o Launcher volta ao lobby com o **resultado**; o **Histórico** guarda todas as partidas.

Sem internet ou sem conta, **Treino vs Bot** joga offline (no Login e no lobby).

**Controles padrão** (remapeáveis em Configurações → Controles): `WASD` move · botão direito ataca e trava o alvo · botão esquerdo arrastado gira a câmera · `Q`/`E`/`R` habilidades · `F` interage · roda do mouse (ou `=` / `-`) aproxima e afasta a câmera.

**Configurações** ficam em `%APPDATA%\rrb-moba\settings.cfg` (vídeo, áudio, controles, gráficos e câmera; o Launcher grava e o Game lê). Créditos e licenças de terceiros: Launcher → Configurações → Créditos.

---

## Para desenvolver

### Pré-requisitos

| O quê | Para quê |
| --- | --- |
| Windows + PowerShell | os scripts de `tools/` |
| **Godot 4.7.2** (build padrão, não .NET) | Launcher, Game e testes |
| Node 24+ e pnpm | backend e site (`engines` do `backend/package.json`) |
| Docker Desktop | Postgres e servidores de partida |
| `gh` (GitHub CLI) | fluxo de issues e PRs |

### Instalação (uma vez por clone)

```powershell
# 1. Godot: grava GODOT_PATH (variável de usuário) e importa o projeto. Ajuste -GodotDir se necessário.
powershell -ExecutionPolicy Bypass -File tools\setup-godot-mcp.ps1 -GodotDir C:\Desenv\engine\godot

# 2. Junctions de shared/ nos dois projetos (ADR-0003). Sem isso o editor abre com erros de res://shared.
.\tools\link-shared.ps1

# 3. Dependências do backend (só se for mexer nele ou rodar o fluxo online)
pnpm -C backend install
```

Clone novo não tem `.godot/`: rode `& ($env:GODOT_PATH -replace '\.exe$','_console.exe') --headless --path game --import` (e o mesmo com `--path launcher`) antes dos testes.

### Subir o Launcher

```powershell
& $env:GODOT_PATH --path launcher          # abre o Launcher (janela)
& $env:GODOT_PATH -e --path launcher       # abre no editor
```

Argumentos do Launcher (depois de `--`):

| Argumento | Para quê |
| --- | --- |
| `--api=<url>` | URL do backend. Padrão: o embutido no pacote (`build_config.cfg`) ou `http://127.0.0.1:3000` |
| `--game-path=<exe>` | executável do Game em dev, ex.: o `*_console.exe` do Godot (sem isso procura `<launcher>\game\game.exe`) |
| `--game-project=<pasta>` | projeto do Game a abrir, ex.: `<repo>\game` (junto com `--game-path`) |
| `--gallery` | abre a galeria do design system |

Para ver saída e erros no terminal use o `*_console.exe`; o `.exe` principal não imprime.

**Sem backend** (só o Game): o treino vs bot fica no Lobby, depois do login (F81); para rodar o Game offline direto:

```powershell
& $env:GODOT_PATH --path game -- --offline --bot
```

### Fluxo online completo na sua máquina

Backend + Postgres + servidor de partida no Docker + Launcher(s) apontando para ele. É o mesmo caminho do pacote, só que local.

```powershell
# 1. Postgres (porta 5432; credenciais só de dev em infra/docker-compose.yml)
docker compose -f infra/docker-compose.yml --profile backend up -d postgres

# 2. Imagem do servidor de partida (binário exportado; rebuild a cada mudança do Game)
docker build -f infra/gameserver/Dockerfile -t rrb-gameserver:latest .

# 3. Backend — rode de dentro de backend/ (as migrações usam caminho relativo)
cd backend; pnpm build
$env:DATABASE_URL     = 'postgres://rrb:rrb@127.0.0.1:5432/rrb'
$env:JWT_SECRET       = 'dev-local-nao-usar-em-producao-0123456789'      # ≥ 32 caracteres
$env:INTERNAL_SECRET  = 'dev-interno-nao-usar-em-producao-0123456789'    # ≥ 32 e diferente do JWT_SECRET
$env:PORT             = '3000'
$env:POOL_SIZE        = '0'     # sem servidor pré-aquecido
$env:POOL_MAX         = '1'     # um servidor basta para um 1x1; a VM do Docker Desktop costuma ser pequena
$env:GAMESERVER_PUBLIC_HOST = '127.0.0.1'
$env:GAMESERVER_BACKEND_URL = 'http://host.docker.internal:3000'
node dist/src/main.js           # confira: curl http://127.0.0.1:3000/health

# 4. Dois Launchers (um por janela), cada um com a sua conta
& $env:GODOT_PATH --path launcher -- --api=http://127.0.0.1:3000 `
  --game-path="$($env:GODOT_PATH -replace '\.exe$','_console.exe')" --game-project="$PWD\..\game"
```

Crie duas contas, entre na fila nas duas e o Launcher abre o Game com o servidor e o token da partida. As variáveis do backend estão comentadas em `backend/.env.example`. Se o Docker travar com pouca memória, deixe `POOL_MAX=1` e não suba outras pilhas junto.

**Só o servidor, sem backend** (teste de rede/Game, qualquer cliente entra e o resultado não é reportado):

```powershell
.\tools\run-server.ps1                  # headless na porta 7000, sem Docker
.\tools\run-clients.ps1 -Autopilot     # 2 clientes lado a lado (o 2º em autopilot)
docker compose -f infra/docker-compose.yml up --build   # o mesmo servidor, no Docker
$env:NETEM_DELAY_MS=100; $env:NETEM_LOSS_PCT=2; docker compose -f infra/docker-compose.yml up --build   # com 100 ms e 2% de perda
```

### Testes

```powershell
.\tools\test.ps1 -Module game        # Game + shared (GUT)
.\tools\test.ps1 -Module launcher    # Launcher + shared (GUT)
pnpm -C backend test                 # backend (unit); test:e2e precisa do Postgres
```

A CI roda também `gdlint` e `gdformat --check` (`pip install 'gdtoolkit==4.*'`). Detalhes em `docs/CI-PR.md`.

### Gerar o pacote ZIP e publicar

```powershell
.\tools\build-package.ps1 -ApiUrl https://<dominio-do-backend> -Version v0.x.y   # → build\LootStart-<versão>-win64.zip
```

Precisa dos export templates do Godot 4.7.2. O ZIP leva `LootStart.exe/.pck`, `game\game.exe/.pck` e `LEIA-ME.txt`, com a URL do backend embutida no Launcher (`--api=` ainda vence). A publicação é por tag anotada `v0.x.y` na `main` com CI verde (`.github/workflows/release.yml`); a variável de repositório `RRB_API_URL` define a URL. Deploy do backend e dos servidores de partida no VPS (Coolify, UDP 7000–7020): `infra/README.md`.

### Estrutura

```text
game/       projeto Godot A — partida (cliente + servidor dedicado)
launcher/   projeto Godot B — fora da partida (telas, serviços, fila)
shared/     comum aos dois (Resources .tres, regras puras, Theme, assets) — junction em game/ e launcher/
backend/    NestJS + Postgres: auth, fila, orquestrador, partidas
infra/      Docker do game server, compose de dev e de produção, deploy
site/       site público (landing Loot Start) — React + Vite, publicado no GitHub Pages
art/        fontes .blend (Blender); o Godot só importa o .glb exportado
tools/      scripts PowerShell (setup, testes, servidor, clientes, pacote, roadmap)
docs/       PRD, ADRs, arquitetura, status e convenções
```

### Site público

Landing page "Loot Start" em `site/` (React + Vite), no ar em https://rodreis.github.io/rrb-godot/. `pnpm -C site install` uma vez, depois `pnpm -C site dev` abre em `http://localhost:5173`. Os dados (heróis, roadmap, capturas) são extraídos em build de `shared/data/heroes`, `docs/roadmap/historia.json` e `docs/STATUS.md`. O merge na `main` publica no GitHub Pages pelo workflow `site`. Detalhes: `docs/SITE.md`.

### Argumentos do Game (depois de `--`)

`--server`, `--port=7000`, `--connect=host:porta`, `--token=<match_token>`, `--offline --bot`, `--autopilot` (`--autopilot=bot` joga pelo `BotInput`), `--bots` (servidor com dois bots, usado pelo soak). Lista completa em `game/scripts/core/launch_args.gd`. Servidor dedicado de dev: `--no-backend` (sem ele exige `BACKEND_URL`, `INTERNAL_SECRET` e `SLOT_PORT` e só aceita cliente com token de partida).

### Onde ler mais

- `docs/ARCHITECTURE-LAUNCHER.md` — Launcher, backend e o contrato Launcher ↔ Game (argumentos, códigos de saída, `settings.cfg`).
- `docs/ARCHITECTURE-GAME.md` — camadas, FSM da partida, rede.
- `docs/DEVELOPMENT.md` e `docs/STATUS.md` — ordem de execução e andamento.
- `docs/SITE.md` — site público (landing Loot Start): dados, marca, deploy e CI.
- `docs/GITHUB.md`, `docs/PRS.md`, `docs/CI-PR.md` — branches, commits, PRs e CI.
