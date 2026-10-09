# CI-PR.md — Política de PR rápida

Jobs paralelos por módulo, **um gate agregado**, duração medida, limites explícitos. Complementa `GITHUB.md` (fluxo) e `PRS.md` (conteúdo da PR). Mantido pelo Code.

## 1. Princípios

1. **Uma PR, um `gate`.** O ruleset da `main` exige só o status `gate`; os jobs por módulo alimentam o gate. Adicionar job não muda o ruleset.
2. **Só roda o que a PR tocou** (path filter). `shared/` toca `game` e `launcher`. `docs/**` sozinho roda só `lint-docs`.
3. **Duração-alvo: ≤ 8 min do push ao `gate` verde.** Medida em todo run (`§5`); acima de 12 min em 3 PRs seguidas é card `[INFRA]`.
4. **Sem flake tolerado:** teste intermitente é desativado com `[FIX]` aberto no mesmo dia, nunca re-rodado "até passar".
5. **CI é a única prova.** Hook local (`lefthook`) roda lint rápido no `pre-push`, mas não substitui nada.

## 2. Jobs (GitHub Actions, `.github/workflows/ci.yml`)

| Job | Dispara em | O que roda | Alvo |
|---|---|---|---|
| `changes` | sempre | `dorny/paths-filter` → saídas `game`, `launcher`, `backend`, `shared`, `infra`, `docs` | 10 s |
| `lint-gd` | `game`, `launcher`, `shared` | `gdlint` + `gdformat --check` (gdtoolkit 4.x) em `*.gd` tocados; grep de literais numéricos em `scripts/core/` e `shared/core/` (I4); grep de `netfox`/`ENet` em `launcher/` (I9) | 1 min |
| `test-game` | `game` ou `shared` | `godot --headless --path game --import` → GUT `game/test` + `shared/test` (`-gexit`, saída JUnit) | 3 min |
| `test-launcher` | `launcher` ou `shared` | idem em `launcher/`; smoke de instanciação das 5 telas e da galeria | 3 min |
| `test-backend` | `backend` | `pnpm install --frozen-lockfile`, `tsc --noEmit`, `eslint`, `jest` unit, e2e com Postgres (`services:`) | 4 min |
| `build-server` | `game`, `shared`, `infra` (a partir de F5) | `docker build infra/gameserver` (cache de camadas) | 3 min |
| `export-check` | `game`, `launcher` (a partir de F28) | `--export-debug` dos presets Windows e Linux-server, sem publicar | 4 min |
| `lint-docs` | `docs` | links internos (`lychee --offline`), `markdownlint` | 30 s |
| `gate` | sempre, `needs: [todos]`, `if: always()` | falha se qualquer job necessário falhou ou foi cancelado; **sucesso se os jobs pulados foram pulados por path filter** | 5 s |
| `soak` (workflow separado, nightly + manual) | cron 03:00 BRT | `tools/soak.ps1`-equivalente Linux: 50 partidas bot × bot headless | 30 min, fora do gate |

Godot na CI: `chickensoft-games/setup-godot` fixado em `4.7.2` (ou imagem Docker própria em `infra/ci/` se a action não oferecer a versão — decidir em F1, registrar aqui). Cache: `~/.cache/pnpm`, `.godot/imported` por módulo (chave = hash dos `.import`).

**Decisão F1 (#2):** binário oficial `Godot_v4.7.2-stable_linux.x86_64.zip` baixado por `curl` e guardado em `actions/cache` (sem action de terceiro); os testes rodam pelo mesmo `tools/test.ps1` local, via `pwsh`. Implementado hoje: só `test-game` (sem path filter) + `gate`. `changes`, `lint-gd`, `lint-docs` e os demais jobs entram por card `[INFRA]`.

## 3. Path filter

```yaml
game:     ['game/**', 'tools/test.ps1', 'tools/link-shared.ps1']
launcher: ['launcher/**', 'tools/test.ps1', 'tools/link-shared.ps1']
shared:   ['shared/**']
backend:  ['backend/**']
infra:    ['infra/**', '.github/workflows/**']
docs:     ['docs/**', '*.md']
```

`shared` ⇒ `test-game` **e** `test-launcher`. `infra` ⇒ tudo (mudança de workflow prova tudo).

## 4. Limites (falham o job)

| Limite | Valor | Onde |
|---|---|---|
| GDScript sem tipo | 0 (`untyped_declaration` = erro no `project.godot`) | `lint-gd` |
| Literal numérico em `core/` fora de constante nomeada | 0 | `lint-gd` (script `tools/ci/no-magic-numbers.ps1`/`.sh`) |
| Referência a `netfox`, `ENetMultiplayerPeer`, `res://scenes/arena` em `launcher/` | 0 | `lint-gd` (I9) |
| Função pública em `core/`/`shared/core` sem teste | 0 | `test-game` (script compara `func` públicas × nomes de teste) |
| Orphan nodes nos testes GUT | 0 | GUT `-gorphans` |
| Cobertura backend (linhas) | ≥ 80 % em `src/**/*.service.ts` | `test-backend` |
| Tamanho da imagem do game server | ≤ 300 MB | `build-server` |
| Duração do `gate` | ≤ 12 min (aviso em 8) | `§5` |

## 5. Medição

Cada run grava em `docs/ci/durations.csv` (via job `measure`, commit de bot **não** — artefato do run; o Code consolida mensalmente em `PRS.md` §métricas): `run_id, pr, sha, job, started, duration_s, result`. Métricas derivadas: p50/p95 por job, rodadas de CI por PR (quantos pushes até verde), taxa de flake.

## 6. O que a CI não faz

Verificação visual (do PI), teste de rede com 2 máquinas reais (manual, roteiro em `game/test/net`), publicar release (manual, `GITHUB.md` §8), deploy (Coolify, manual até F28).
