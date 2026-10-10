# Roteiro F14 — Arqueira: básico, Q Flecha Perfurante, E Rolamento, R Chuva de Flechas (SPEC-014, #62)

O Code sobe tudo (`CLAUDE.md`); o PI só joga e olha. Modo host com bot no nível 6: `& $env:GODOT_PATH --path game -- --offline --bot --level=6`. Na seleção, tecla `2` (Arqueira) e `Espaço`; o bot (time B) também é Arqueira (padrão do slot P2).

Valores esperados no nível 6 (GDB §2.2, §4.2; ranks típicos Q3 E2 R1): HP 520, DEF 16, ATK 80, INT 22,5 (CDR 11,25 %), AGI 36. Dano no outro herói já descontada a DEF 16 dele.

| # | Ação | Esperado |
|---|---|---|
| 1 | Seleção | Arqueira disponível; modelo com capa azul e arco na mão esquerda |
| 2 | Andar e mirar | Corre com animação; vira para o cursor |
| 3 | Básico (LMB) | Flecha sai reta, some a **9 u**; no herói tira **69** (80 bruto); em monstro tira 80; recarga ~0,66 s |
| 4 | Básico em muro, pilar, portão inimigo | A flecha **para** no obstáculo; no rio **passa** |
| 5 | **Q** em fila (2 monstros alinhados) | Flecha atravessa: 1º perde **211**, 2º **179** (−15 %); alcance **11 u**; recarga ~6,2 s |
| 6 | **E** andando | Rola **4,2 u** na direção do movimento em 0,35 s; parado, rola para a frente; durante ~0,3 s **não perde HP**; logo depois o básico já está pronto; recarga ~7,3 s |
| 7 | **R** com o cursor a ~5 u | Disco azul de raio 4 u no ponto do cursor (cursor além de 8 u: cai a 8 u); **6 pulsos** em 3 s, **41** por pulso no herói (48 bruto); quem está dentro fica `(lento)` e anda mais devagar; recarga ~39,9 s |
| 8 | Bot de Arqueira | Atira de longe (≤ 9 u), usa Q em linha e R no alvo; farma e luta sem travar |
| 9 | Fechar | Log sem `ERROR` |
