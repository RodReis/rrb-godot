# [FIX] #228 e #229 — Seleção de heróis (2026-10-19)

Achados do PI na verificação visual do F79. Tela: F51 / SPEC-051 (`game/scenes/ui/hero_select.tscn`).

## #228 — layout não cabia

**Medido** com `tools/ui/hero_select_showcase.gd` (unidades da base 1920×1080, `canvas_items` + `expand`):
o `Column` pedia **1488** de altura contra 1080 (estoura em 408). O culpado era o `RosterCard`, mínimo
**1319**: a grade de 10 heróis (F76–F78) em 3 colunas virava 4 linhas altas. Os previews pediam só 850.
Não é de tela cheia: já estourava em 1280×720 (o stretch mantém a proporção); a tela cheia só deixa o corte
mais evidente. O topo (cabeçalho) e o rodapé (botão de confirmar, atributos) ficavam fora da janela.

**Correção:** grade de **5 colunas × 2 linhas** (`columns = 5`) e o card dos heróis mais largo
(`size_flags_stretch_ratio = 2.0`; os previews só precisam de ~408). Depois: `Column` mínimo **1041** (cabe
em 1080) e tamanho 1080.

Prova: teste `test_dez_herois_cabem_na_base_do_projeto` (monta a tela numa `SubViewport` 1920×1080 e exige
mínimo ≤ base): falha com a cena antiga (1488) e passa com a nova. Capturas: `antes-2560x1440.webp`,
`depois-1280x720.webp`, `depois-2560x1440.webp`, `depois-3440x1440.webp` (ultrawide).

## #229 — herói começava de costas

Os previews grandes (`PlayerPreview`/`EnemyPreview`) não definiam `facing` e o padrão do componente é 0 (de
costas nos KayKit); a grade e a ficha já definiam 180. Agora `HeroSelect.PREVIEW_FACING = 180.0` nos dois.
Teste: `test_previews_comecam_de_frente`.

## Verificação

PI aprovou em 2026-10-19, jogo offline contra o bot ao vivo ("ficou bom").

## Não coberto (`not_run`)

Telas de aspecto mais estreito que 16:9 (o `expand`
só cresce na vertical, o mínimo de largura 1392 cabe nos 1920 da base).
