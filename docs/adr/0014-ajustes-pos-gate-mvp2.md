# ADR-0014 — Ajustes do PI depois do [GATE] do MVP2: centro livre, ficha do herói, baú com menu, água e fonte

**Status:** aceito — 2026-10-13
**Decisor:** Rodrigo Reis (PI)
**Supera parcialmente:** SPEC-047 §2 e §3 (baú: `F` segurado, escolha lateral, card de comparação ancorado ao baú) · GDB §6.2 "Regra de Substituição" · `CONVENTION.md` §4.3 · SPEC-034 / SPEC-044 (8 pilares da cratera) · DV tela 5 em partida (tecla `B` = bestiário de monstros)
**Relacionados:** F60 #164 · F61 #165 · F62 #166 · F63 #167 · F64 #168 (o corpo de cada issue vale como spec) · ADR-0006 · ADR-0010

## Contexto

Depois do [GATE] do MVP2 (#69, aprovado em 2026-10-13) o PI jogou e pediu quatro ajustes, antes de começar o MVP3 (Launcher), e mandou criar as issues **no MVP2** (#57), como foi feito com o F56. Os prints mostram: pilares de obsidiana fechando o centro; rio com cara de plástico; `B` abrindo um esqueleto; baú que pede `F` duas vezes e ainda troca por item pior.

## Decisão (pop-ups de 2026-10-13)

1. **Centro livre (F60).** Saem os 8 pilares `obsidian_pillar.glb` da cratera e a colisão deles. Ficam o lago de magma, as 4 entradas e o anel de monstros.
2. **Baú com menu (F61).** `F` abre o baú e mostra **3 itens** sorteados na raridade do baú, distintos entre si; o clique do mouse escolhe; o herói leva 1 e o baú fecha. Enquanto o menu está aberto o cursor é liberado e o herói fica parado (padrão do bestiário); `Esc` fecha sem pegar.
   - O PI **pode escolher item pior** que o equipado; cada card mostra a comparação (+/− por atributo, conjuntos antes → depois).
   - O baú fica **reservado ao primeiro herói que o abriu**: com `Esc` o mesmo herói reabre o mesmo menu com `F`; o adversário não abre baú já aberto.
   - Baú de cura (30 % do comum): aplica na abertura, sem menu. Baú do Rei Esqueleto: menu com 3 épicos distintos, arma inclusa.
   - Itens continuam iguais para todas as classes (nada de arma por classe).
   - Acabam o `F` segurado, o segundo `F` e a escolha lateral automática.
3. **Tecla `B` = ficha do herói (F62).** Mostra o herói que o jogador joga (preview 3D, itens equipados, atributos, 4 habilidades com descrição) com uma aba **Monstros** que mantém o bestiário atual. A decisão do PI de 2026-10-09 (bestiário em partida) continua valendo, agora como aba.
4. **Água do rio (F63).** Shader de água no Godot sobre `river_mana.glb`: normal maps CC0 animados, fresnel, profundidade, espuma na margem e reflexo. Malha/UV no Blender só se precisar.
5. **Fonte de cura (F64).** Pedido do PI no mesmo dia (print): remodelar a fonte no Blender (pedra com textura PBR realista CC0, bica central), com o shader de água do F63 na bacia e partículas da água caindo. Só visual: colisão, raio e regra de cura iguais.
6. **Ordem:** F60 → F61 → F62 → F63 → F64, **antes** do MVP2.6 (#160) e do MVP3. O [GATE] #69 já está aprovado; os quatro cards entram depois dele, como o F56 entrou.

## Alternativas rejeitadas

| Alternativa | Motivo |
|---|---|
| Remover a cratera junto com os pilares | PI escolheu manter o magma |
| 4 pilares em vez de 8 | centro ainda fechado |
| Só trocar a textura da água | sem movimento; PI escolheu shader |
| Malha de rio nova no Blender | custo maior sem ganho pedido |
| Ficha do herói em outra tecla | PI escolheu `B` com aba Monstros |
| Bloquear item pior no menu | PI quer a decisão dele, com a comparação à vista |
| 1 item por slot no menu | ritmo de poder do GDB; PI escolheu 3 itens sorteados |
| Itens por classe | escopo grande; fica para backlog se o PI quiser |
| Esc perde o baú / deixa o baú aberto a todos | PI escolheu reservar a quem abriu |

## Consequências

- GDB §6.2 e `CONVENTION.md` §4.3 atualizados no mesmo commit desta ADR (regra nova de escolha).
- F61 mexe em sorteio (`ChestRules`), regra por herói no servidor (`Chest`), HUD (menu no lugar do `ChestOfferCard`), bot (`BotInput._loot` escolhe o melhor dos 3) e rede (menu reservado). É o maior dos quatro; o soak precisa passar de novo.
- `SPEC-047` fica como histórico; o `ItemRules.offer` continua existindo para o bot e para o card de comparação.
- F62 cria o campo `description` em `SkillData` (hoje há só nome e ícone) e preenche as 4 habilidades dos 4 heróis do MVP2; Ladina e Engenheiro (F58/F59) trazem as suas. Texto só do que já está no GDB, sem regra nova.
- A DV tela 5 (bestiário no Launcher, F34) não muda.
