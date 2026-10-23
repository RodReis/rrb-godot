# SPEC-092 — Primeiras skins: 1 por herói KayKit e a skin do Pacote de Fundador no Carrasco

**Fatia:** F92 / SPEC-092 (MVP5, Slice 5.6) · **Issue:** #261 (issue-pai #250) · **Status:** decidida pelo PI em 2026-10-23 (pop-ups do Cowork: "1 skin por herói KayKit (10)"; "Carrasco" para o Fundador; "Skin fica guardada até a Patente 11")
**ADR:** ADR-0005, ADR-0006, ADR-0025, ADR-0032, ADR-0034 · **Fontes:** `shared/assets/LICENSES.md` (pack KayKit Adventurers 2.0 Extra comprado pelo PI), `art/heroes/build_*.py`, F98 (Carrasco)
**Escopo:** `art/` e `shared/assets/` (skins), `shared/data/` (catálogo de skins). Regras de jogo e código de partida não mudam.

## 1. Skins avulsas (R$ 9,90 cada)

- **10 skins, uma por herói KayKit:** Cavaleiro, Arqueiro, Bárbaro, Bruxo de Fogo, Ladina, Engenheiro, Protetor da Selva, Berserker, Paladino Radiante e Ocultista.
- Onde o pack Extra tem textura alternativa que serve ao modelo do herói (`knight_texture_alt_A`, `barbarian_texture_alt_A`, `mage_texture_alt_A`), ela é a base; o Code confere se o UV do modelo usado bate com a textura do pack. As demais são recolor feito pelo Claude no Blender, por script, sobre o atlas do herói (inclusive Paladino, que já usa `alt_B`, e Ocultista, que tem atlas próprio).
- Mesmo rig, mesmas animações e mesma silhueta; equipamento visível (F48) segue igual.

## 2. Skin do Pacote de Fundador (Carrasco)

- Exclusiva do Pacote de Fundador (SPEC-090). Precisa ser **mais que um recolor**: textura nova do modelo do Tripo + acabamento próprio (ex.: peça ou detalhe no Blender), dentro do orçamento de triângulos do modelo base do F98.
- O Claude apresenta renders das opções; o PI escolhe.
- Só equipa com o Carrasco liberado (Patente 11, ADR-0034).

## 3. Entrega

1. Fonte em `art/heroes/skins/` (scripts `.py` e `.blend`), exportação `.glb`/texturas em `shared/assets/rrb/heroes/skins/`; licença e origem de cada uma em `shared/assets/LICENSES.md`.
2. Catálogo de skins em `shared/data/` (id, herói, nome, preço, Fundador ou avulsa). **Nomes** propostos pelo Claude, aprovados pelo PI.
3. Renders de cada skin na distância da câmera do jogo e na Tela Heróis, para aprovação.
4. Frame time medido com a skin mais pesada (não pode passar do herói base).

## 4. Critério de aceite

1. As 11 skins aprovadas pelo PI por render, depois vistas em partida (com o F91).
2. Cena de alinhamento (PRD §11) sem desvio de escala ou pivô.
3. CI verde.

## 5. Fora

Skin do Carrasco avulsa, skins que mudam silhueta ou animação, variantes por raridade, skins pagas fora do catálogo.
