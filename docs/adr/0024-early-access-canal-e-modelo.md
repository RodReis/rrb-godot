# ADR-0024 — Early Access depois do MVP4, no site próprio e no itch.io, como F2P

**Status:** aceito — decisão do PI em 2026-10-19 (pop-up do Cowork, análise "Loot Start — Early Access, monetização, lojas e engine")
**Data:** 2026-10-19
**Decisor:** Rodrigo Reis (PI)
**Emenda:** PRD §1.1 (fase B), §1.2 (plataforma: "Steam/itch na fase B"), §1.3 (linha Steam), §9.1 (marco novo M5)
**Relacionados:** F28 (#82, VPS e Release v0.1.0) · F83 (#242, instalador) · [GATE] MVP3 #87 · MVP4 · ADR-0025 · ADR-0026 · ADR-0027

## Contexto

O VPS está no ar e o Release v0.1.0 saiu em 2026-10-19, mas o [GATE] MVP3 #87 está aberto e o playtest do MVP4, que o PRD §1.1 exige antes da fase comercial, não começou. O PI pediu uma análise de Early Access, canal de distribuição, modelo de negócio e troca de engine, e decidiu os pontos em pop-up.

## Decisão

1. **Early Access abre depois do [GATE] do MVP4**, e só se o critério do PRD §9.2 passar (≥ 7 de 10 playtesters pedem uma segunda partida). Antes disso não há EA.
2. **Canal:** site próprio (`lootstart.cloud`) + **itch.io**. A Steam fica fora por agora. O F83 (#242, instalador e atualização próprios) segue como está.
3. **Modelo:** free-to-play com **Pacote de Fundador** e loja só cosmética (ADR-0025). Sem Early Access pago.
4. **Marco novo MVP5 — Early Access** (= M5 do PRD), depois do MVP4: progressão de conta, bot na fila online, loja e skins. O [GATE] do MVP5 é a abertura do EA.
5. **Engine:** segue Godot 4.7 (D7). Entra agora um **spike visual** (1 herói + 1 canto da arena com arte de qualidade maior, no pipeline atual) para decidir o caminho visual com dado; a troca para Unity não está em discussão.

## Alternativas descartadas

| Alternativa | Por que não |
|---|---|
| EA antes do MVP4 (o EA vira o playtest) | pula o único portão que mede se o jogo diverte; reviews ruins na estreia |
| Steam como canal principal | decisão do PI; fica como referência na análise para quando voltar à mesa |
| EA pago barato | reduz a população de um PvP 1x1; migrar pago → F2P depois gera revolta |
| Migrar para Unity 6 para melhorar o visual | o limite é a arte (CC0 low-poly, ADR-0006), não o renderer; custaria reescrever Game, Launcher, netcode e testes |

## Consequências

- Sem a descoberta orgânica da Steam, a divulgação é do PI; o bot na fila (ADR-0027) passa a ser o que segura um 1x1 com pouca gente.
- O itch.io não processa compra dentro do jogo: a loja paga pelo backend (ADR-0025).
- O SmartScreen continua avisando no instalador (assinatura de código segue em `FORA-DE-ESCOPO.md`).
- O roadmap público lê o marco `MVP5` do `STATUS.md` §2 sem mudança de código (`tools/roadmap/status.mjs` aceita `MVP<n>`); o capítulo dele em `historia.json` entra quando houver entrega.
- Se a Steam voltar: Early Access lá não pode ter preço maior nem sair depois de outra loja (regras do Steamworks); compras só pela Carteira Steam.
- Vigiar: população online no playtest; se a fila ficar vazia mesmo com bot, o canal é revisto.
