# Roteiro F8 — Cavaleiro: ataque básico, Q Investida, E Muralha, R Terremoto (SPEC-008, #21)

`.\tools\run-server.ps1 -Level 6` + `.\tools\run-clients.ps1 -Autopilot`. A janela 1 é o time A (você); a 2 é o autopilot (time B), que anda em círculo e dá ataque básico a cada ~1,5 s. Leve o seu Cavaleiro até o autopilot (centro ou base B, com o portão B bloqueando o time A até cair).

Valores esperados no nível 6 (GDB §2.2, §4.1; ranks típicos Q3 E2 R1): HP 825, DEF 45, ATK 57,5, INT 15.

| # | Ação | Esperado (nas **duas** janelas) |
|---|---|---|
| 1 | Os dois aparecem | Modelo do Cavaleiro (espada + escudo), `825 / 825`; anda e corre com animação |
| 2 | Ataque básico (LMB) colado no autopilot, de frente | HP dele cai **40** (58 bruto − DEF 45); recarga ~0,9 s |
| 3 | **Q** mirando o autopilot a até 6 u | O Cavaleiro avança em linha reta e **para no alvo**; o autopilot é **empurrado ~1,5 u** e perde **106** (153 bruto) |
| 4 | **E** com o autopilot à frente | Rótulo mostra `+294` por 3 s; golpes do autopilot **pela frente** gastam o escudo (`+254`…) e o HP não cai; golpe pelas costas tira HP |
| 5 | **R** com o autopilot a até 5 u | Autopilot perde **122** (177 bruto) e fica `(atordoado)` ~1,2 s, parado |
| 6 | Recargas | Q ~7,4 s · E ~10,2 s · R ~46,3 s (CDR 7,5 % da INT 15) |
| 7 | Fechar | Servidor sem `ERROR` |

## Execução — 2026-10-09 (PI, servidor `-Level 6` e clientes locais, autopilot)

| Passo | Resultado |
|---|---|
| 1 | OK. Modelo com espada e escudo, `825 / 825`, animações |
| 2 | Não informado pelo PI |
| 3 | OK |
| 4 | OK (`+294` no rótulo) |
| 5 | OK |
| 6 | Não verificável a olho: sem HUD de recarga até o F13; recargas cobertas por GUT (`test_skill_rules.gd`) |
| 7 | OK. Log do servidor com 0 `ERROR` |

PI: "todas as skill funcionando … está tudo ok".
