# SPEC-093 — Spike visual, parte 2: Cavaleiro comissionado no estilo Eternal Return, jogável na cena do F84

> **CANCELADA em 2026-10-21 (ADR-0032).** O PI trouxe a arte gerada no Tripo e decidiu que ela vira o 11º herói, o Carrasco (F98 / SPEC-098, mesma issue #248). Mantida só como histórico.

**Fatia:** F93 / SPEC-093 (MVP4, Slice 4.6 — depois do F84 e da entrega do artista) · **Issue:** #248 (issue-pai #246) · **Status:** decidida pelo PI em 2026-10-19 (pop-ups do Cowork: "Herói comissionado, cenário no Blender"; "Partir em 2"; "As 8 do Cavaleiro de hoje"; ".glb + .blend fonte"; "Cowork escreve, você envia")
**ADR:** ADR-0024 item 5 · **Par:** SPEC-084 (F84) · **Briefing do artista:** `docs/prd/BRIEFING-ARTISTA-CAVALEIRO.md`
**Fontes:** ADR-0005, ADR-0006 (não muda nesta fatia), ADR-0010 (equipamento preso a ossos) · `game/scenes/heroes/knight.tscn` (cápsula r 0,4 × 1,8 u; modelo KayKit em escala 0,78, girado 180°) · `game/scripts/net/hero_visual.gd` (clipes exportados por nome)
**Escopo:** só visual do Cavaleiro, só na cena variante do F84. Gameplay, números, colisão, rede e o Cavaleiro da arena oficial não mudam.

## 1. Motivo

Fecha o spike visual: com o cenário do F84 e um Cavaleiro de qualidade profissional no mesmo estilo, o PI joga e decide se o caminho visual do produto é arte comissionada, pacote comprado ou arte própria (ADR-0024). O herói é comissionado porque modelar e animar um personagem semi-realista com rig novo por script não alcança a referência.

## 2. Pré-condição (fora do board)

O PI contrata o artista com o briefing (`BRIEFING-ARTISTA-CAVALEIRO.md`) e combina preço, prazo e direitos de uso. O card só vai para `todo` quando os arquivos do artista estiverem no repositório (`art/spike/f93/`).

## 3. Entrega

1. **Importação:** `.glb` do artista em `shared/assets/rrb/spike/f93/knight_er.glb`; `.blend` fonte em `art/spike/f93/`. Passa pela cena de alinhamento (PRD §11) para escala e orientação contra a cápsula de 1,8 u.
2. **Cena do herói variante** `game/scenes/heroes/knight_spike_f93.tscn`: mesma cápsula, script e dados do Cavaleiro; troca só o nó `Model` e os nomes de clipe do `Visual` (`hero_visual.gd` já exporta `idle`, `run`, `dash`, `block`, `stunned`, `basic_attack`, `skill_r`, `death`).
3. **Só na variante:** com o argumento de dev do F84 (ou um par dele, ex.: `--hero-spike=f93`), o jogador que escolhe o Cavaleiro recebe o visual novo. O bot e a arena oficial seguem com o Cavaleiro KayKit.
4. **Equipamento:** espada e escudo vêm no modelo do artista. A troca visual de arma/armadura por item (ADR-0010) fica **desligada** no herói variante; o card registra quais ossos de fixação o artista entregou, para a fatia futura.
5. **8 clipes** mapeados (briefing §5). Clipe que vier com defeito vira nota na PR e no retorno ao artista, não correção do Code no Blender.

## 4. Orçamento

Até ~2× o ADR-0006: personagem ≤ 6.000 triângulos, texturas PBR ≤ 2K (cor, normal, ORM), 1–2 materiais. Frame time medido na base SO com o herói variante.

## 5. Critério de aceite

1. Treino offline na variante: o Cavaleiro novo anda, corre, investe (Q), bloqueia (E), fica atordoado, ataca, usa o R e morre, cada ação no clipe certo, sem pé deslizando visível na câmera de 11 u.
2. Sem regressão: o Cavaleiro oficial e os outros 9 heróis iguais; soak curto (`soak.ps1 -Count 10 -Require knight`) verde.
3. Frame time registrado em `docs/evidencias/f93/` (F84 com KayKit × F84 com o herói novo).
4. Capturas e vídeo curto (movimento) em `docs/evidencias/f93/` e no roadmap.
5. **Verificação do PI jogando a cena.** O PI registra a decisão final do caminho visual; vira ADR do Cowork.
6. CI verde.

## 6. Fora

Outros heróis, skins, levar o herói para a arena oficial e para o bot, equipamento por item no herói novo, mudanças de gameplay.
