# FIX #238 — bot do treino parado no ponto lembrado do monstro

Treino `--offline --bot` (headless), posição do bot a cada 60 ticks, Arqueira no time B.

**Antes (causa):** o bot viu o Monster40 fora de casa (perseguindo), o monstro voltou ao acampamento
`(25,8; 2,2)` fora do raio de visão (12 u) e a memória da neblina ficou com o ponto antigo
`(21,7; -3,3)`. O bot parou a 8,5 u desse ponto (alcance do básico 9,0 − margem 0,4), mirou e "atirou"
no vazio: posição fixa em `(17,4; -10,5)` de t=3420 a t=3780 com `baseM=3` (3 monstros vivos da base),
`sees=false`, `tid=-40`.

**Depois:** ponto lembrado à vista e vazio → o bot procura na casa do monstro; casa vazia à vista →
deixa de contar com ele. Mesmo cenário: t=3420 em `(21,2; -4,8)`, base zerada em t=3660
(`baseM` 3 → 2 → 1 → 0), depois LOOT.

Teste GUT: `test_bot.gd` (`test_ponto_lembrado_vazio_a_vista_manda_procurar_na_casa_do_monstro`,
`test_casa_do_monstro_a_vista_e_vazia_tira_o_monstro_dos_alvos`). Suíte game 1749/1749.
Soak `-Count 8 -Parallel 8`: 8/8 com vencedor, 0 falhas, 373–506 s de jogo.

Observação: o recuo à fonte (~23 s parado curando até 70 % de HP) é regra do #74, não deste bug.
