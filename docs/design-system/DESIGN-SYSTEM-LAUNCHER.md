# DESIGN-SYSTEM-LAUNCHER.md — Contrato de design

**Contrato da verdade para aparência e comportamento visual** do Launcher **e** da HUD do Game (mesmo Theme). Dividido em quatro documentos; este é o índice e as regras de uso.

| Documento | O que fixa |
|---|---|
| [`TOKENS.md`](TOKENS.md) | cores semânticas, tipografia, espaçamento, raios, tamanhos, durações — e como viram `Theme` |
| [`COMPONENTS.md`](COMPONENTS.md) | componentes reutilizáveis (cenas em `shared/ui/components/`): API, variantes, estados |
| [`PATTERNS.md`](PATTERNS.md) | composições: layouts de tela, navegação, feedback, raridade, timers |
| [`DEBITO.md`](DEBITO.md) | o que está fora do contrato de propósito, com dono e gatilho |

Origem visual: `docs/prd/DESIGN-VISUAL-LAUNCHER.md` §1 (filosofia, paleta, tipografia, viewport). Este contrato **traduz** aquele documento para o Theme do Godot; onde divergir, vale o contrato — e a divergência é registrada em `DEBITO.md`.

## Princípios (DV §1.1, resumidos)

1. **Legibilidade em alta velocidade:** HP, cooldown e zona lidos em < 100 ms — contraste alto, números grandes, monoespaçado em contadores.
2. **Um Theme:** tudo deriva de `shared/ui/theme/theme_moba.tres`; variação por `theme_type_variation`, nunca `add_theme_*_override` em cena (exceção documentada em `DEBITO.md`).
3. **Cor semântica:** ouro = título/recompensa/primário; azul = aliado/INT/Guarda; vermelho = perigo/inimigo; verde = vida/vitória; roxo = épico/boss/ultimate. Cor nunca é o único portador de significado.
4. **Diegético × HUD:** barras flutuantes, retículas e círculo da zona no mundo 3D; HUD ancorada nas bordas. Nada no centro da tela além de alertas de fase.

## Como o contrato vira código

- `TOKENS.md` → `shared/ui/theme/tokens.gd` (constantes tipadas, `class_name UiTokens`) **e** `theme_moba.tres` (gerado/ajustado no editor a partir das constantes). O `.tres` é a fonte para o Godot; `tokens.gd` é a fonte para código (tween, shader, `_draw`). Os dois têm de bater — teste GUT em `shared/test/test_theme_tokens.gd` compara.
- `COMPONENTS.md` → uma cena por componente em `shared/ui/components/<nome>.tscn` + script `class_name` com API pública tipada.
- Nova cor, fonte ou componente **sem entrada aqui** é P1 em revisão.

## Quem mantém

Cowork (planejamento) escreve e altera o contrato; Code implementa o Theme e os componentes e abre `[FIX]` quando o contrato é inexequível. Mudança visual que o PI pede na verificação visual entra primeiro aqui, depois no código.
