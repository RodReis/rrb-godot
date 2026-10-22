# SPEC-086 — Publicação no itch.io: página do jogo e ZIP a cada Release

**Fatia:** F86 / SPEC-086 (MVP4, Slice 4.5) · **Issue:** #252 (issue-pai #246) · **Status:** decidida pelo PI em 2026-10-22 (pop-ups do Cowork: "ZIP portátil"; "PI cria a conta e grava o segredo"; "Página restrita por senha"; "Cowork redige, PI aprova"; "Launcher desliga o atualizador próprio no itch")
**ADR:** ADR-0024 item 2 (canal itch.io) · emenda ao ADR-0023 item 5 (o atualizador próprio não roda na build do itch)
**Fontes:** F83/SPEC-083 (instalador, `latest.json`, `X-Client-Version` e `426`), F28 (`build-package.ps1`, ZIP), `.github/workflows/release.yml`, `launcher/scripts/services/build_info.gd` e `update_service.gd`
**Escopo:** infra e CI (`release.yml`, `tools/build-package.ps1`), mais uma mudança pequena no Launcher (canal da build). Regras de jogo, backend e contrato Launcher ↔ Game não mudam.

## 1. Motivo

O ADR-0024 pôs o itch.io como segundo canal do Early Access, ao lado do site próprio. O site distribui só o instalador (ADR-0023 item 2). O itch.io distribui o ZIP portátil e o app do itch instala e atualiza por conta própria.

## 2. Pré-condições do PI (fora do código)

1. Criar a conta e o projeto do Loot Start no itch.io. Tipo "Downloadable", Windows, **grátis** (ADR-0024: F2P).
2. Pôr a página em **Restricted** (acesso por senha). Só abre ao público quando o PI decidir (início do playtest).
3. Gerar a API key do itch.io e gravar no GitHub, em Settings > Secrets, como **`BUTLER_API_KEY`**.
4. Gravar em Settings > Variables a variável **`ITCH_TARGET`** = `usuario/projeto` (o slug da página).

O Code não cria conta, não guarda credencial no repositório e não configura a página no painel do itch. Faltando `BUTLER_API_KEY` ou `ITCH_TARGET`, o job do itch falha com erro explícito (mesmo padrão do `VPS_UPLOAD_KEY`).

## 3. Entrega

### 3.1 Build do itch (`tools/build-package.ps1`)

- Parâmetro novo `-Channel` (`site` por padrão, ou `itch`).
- Com `-Channel itch`, o `build_config.cfg` gravado no pacote leva `[build] channel="itch"` e **`update_url=""`**. Sem `update_url` o `UpdateService` já não checa atualização (`BuildInfo`: sem URL, sem checagem).
- Com `site`, nada muda: o pacote e o instalador seguem como no F83.
- O ZIP do itch se chama `LootStart-<versão>-win64.zip` (nome atual do ZIP do F28).

### 3.2 Launcher

- `BuildInfo.channel()` lê `[build] channel` (padrão `site`).
- No canal `itch`, quando o backend recusa a fila com `426` (versão menor que `MIN_CLIENT_VERSION`), a mensagem diz para **atualizar pelo app do itch.io** e **não** oferece baixar o Setup. O Code confere como o `426` aparece hoje e reaproveita o mesmo ponto.
- O treino contra bot segue livre (ADR-0023 item 6).
- Teste GUT: `channel` lido do arquivo; padrão `site`; canal `itch` não oferece o Setup.

### 3.3 CI (`.github/workflows/release.yml`)

- O job `package` também gera o ZIP do itch (segunda passada do `build-package.ps1 -Channel itch`) e o sobe como artefato do run.
- **Job novo `itch`** (`needs: package`, só em tag `v*`): baixa o ZIP, instala o **butler** e roda `butler push <zip> "$ITCH_TARGET:windows" --userversion "<tag>"`. Canal do itch: `windows`.
- Job separado de propósito: falha do itch **não** desfaz o GitHub Release nem o envio ao VPS, e dá para rodar de novo sozinho.
- Segredo só por variável de ambiente (nunca no texto do script). Tag validada como no passo do VPS.
- Versão do butler fixada no workflow.
- Ensaio manual (`workflow_dispatch`): gera o ZIP do itch como artefato e **não** envia.
- Medir e registrar na PR o tempo extra da segunda passada no `package` (limite atual: 30 min).

## 4. Textos e capturas da página (Cowork redige, PI aprova)

Rascunho. O PI aprova ou corrige antes de publicar. O texto só usa o que o jogo já faz; nada de preço, loja, regras novas ou termos legais.

- **Título:** Loot Start
- **Resumo (uma linha):** MOBA 3D de dois tempos: 5 minutos de preparação e depois a luta dentro de uma zona que fecha.
- **Descrição:**
  - Partida em dois tempos. Na preparação você abre baús, enfrenta monstros e monta seu herói. No confronto, uma zona fecha o mapa e o último time de pé vence.
  - 10 heróis jogáveis: Cavaleiro, Arqueiro, Bárbaro, Bruxo de Fogo, Ladina, Engenheiro, Protetor da Selva, Berserker, Paladino Radiante e Ocultista.
  - Partidas online pela fila, com servidor autoritativo. Treino contra bot, sem fila.
  - Windows. Precisa de conta (e-mail e senha) e de internet para jogar online.
  - Em playtest: o jogo muda entre versões e o app do itch.io atualiza sozinho.
  - Aviso do Windows (SmartScreen): o executável não tem assinatura de código. Clique em **Mais informações** e depois em **Executar assim mesmo**.
- **Gênero e tags:** Action, Strategy; moba, multiplayer, pvp, 3d, fantasy.
- **Preço:** grátis.
- **Capturas:** até 5, escolhidas pelo Code em `docs/roadmap/` e `docs/evidencias/` (arena, seleção de heróis, partida, HUD). O PI aprova a escolha.
- O Code grava o texto aprovado em `docs/ITCH.md` (cópia para colar no painel do itch). Quem cola é o PI.

## 5. Critério de aceite

1. Testes do Launcher (GUT) conforme §3.2. Suíte do launcher verde.
2. `build-package.ps1 -Channel itch` gera ZIP cujo `build_config.cfg` tem `channel="itch"` e `update_url=""`; com `site`, o `build_config.cfg` fica igual ao do F83. Saída mostrada.
3. `release.yml` validado por lint de workflow e por ensaio `workflow_dispatch` (ZIP do itch como artefato, sem envio). Saída do CI mostrada, com `gh run` ou `gh pr checks`.
4. Tempo da segunda passada medido e registrado.
5. **Verificação do PI**, depois de cumprir §2 e com o primeiro Release em tag: o ZIP aparece no canal `windows` da página restrita; instalar pelo app do itch.io, abrir o Launcher, ver a versão no rodapé, entrar na fila online e treinar contra bot; o Launcher não oferece baixar o Setup.
6. CI verde.

## 6. Fora

Steam, página pública (decisão do PI no início do playtest), pagamento pelo itch.io (ADR-0024), canal de pré-lançamento, patch só do `.pck`, assinatura de código, configurar a página no painel do itch.
