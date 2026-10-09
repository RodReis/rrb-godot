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
| 6 | Recargas | Q ~7,6 s · E ~10,5 s · R ~47,9 s (CDR 7,5 % da INT 15) |
| 7 | Fechar | Servidor sem `ERROR` |

## Execução

(preencher)
