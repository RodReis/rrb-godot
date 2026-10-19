# F79 — Tipo de tela: evidência (2026-10-19)

Fatia SPEC-079 (issue #226, ADR-0019). Seletor **Tipo de tela** nas Configurações do Launcher; contrato
`[video] window_mode` no lugar de `fullscreen`.

## Prova

| O quê | Resultado |
|---|---|
| GUT `launcher` + `shared` | **719/719** |
| GUT `game` + `shared` | **1716/1716** |
| `gdlint` e `gdformat --check` (gdtoolkit 4.x) nos 6 arquivos `.gd` alterados | limpos |
| `tools/ci/no-magic-numbers.ps1` | ok |

Testes novos: leitura de `window_mode`, valor inválido → padrão (`"lixo"`, `""`, `2`, `true`, `1.5`), legado
`fullscreen` (`true` → sem borda, `false` → janela, tipo errado ignorado, `window_mode` presente vence,
`window_mode` inválido não cai no legado), padrão sem arquivo = sem borda, escrita sem `fullscreen`, mapeamento
modo → `Window.Mode`, só o Modo Janela usa a resolução, e na tela: 3 opções na ordem do contrato, escolher grava
no rascunho e desabilita a resolução, valor salvo volta selecionado.

## Captura

`launcher-configuracoes-tipo-de-tela.webp`: aba "Gráficos & Performance" no Launcher (1920×1080). Mostra
**Modo Janela** porque o `settings.cfg` desta máquina tinha o `fullscreen=false` antigo: a migração o leu como
`windowed` e a resolução (1280 × 720) ficou habilitada.

## Doc da engine (4.7, `Window.Mode`)

`MODE_FULLSCREEN` e `MODE_EXCLUSIVE_FULLSCREEN` cobrem o monitor, **não trocam o modo de vídeo** e forçam a
janela ao tamanho do monitor; entrar em tela cheia força `borderless=true` (por isso o applier faz
`borderless=false` ao voltar para janela). A exclusiva tem menos overhead, só uma janela por tela, e no
Windows pode piscar a tela na transição.

## Não coberto (`not_run`)

- Os 3 modos **em janela real** (Launcher e Game): verificação visual do PI.
- Exclusiva em monitor com resolução diferente da do jogo: depende do driver (doc 4.7).
