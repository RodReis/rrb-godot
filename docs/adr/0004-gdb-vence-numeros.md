# ADR-0004 — Em divergência numérica, o GDB vence o PRD

**Status:** aceito — 2026-10-08
**Decisor:** Rodrigo Reis (PI)
**Relacionados:** `docs/prd/PRD.md`, `docs/prd/GDB.md`, `CONVENTION.md`, `RASTREABILIDADE.md`

## Contexto

O PRD (v0.1) e o GDB (v1.0) foram escritos no mesmo dia; o GDB é mais detalhado e mais recente. Divergem em pelo menos estes pontos:

| # | Tema | PRD | GDB | Vale |
|---|---|---|---|---|
| N1 | Bônus set Caçador 3/3 | +10% vel. ataque | +10% vel. ataque **e +8% vel. movimento** | GDB |
| N2 | Bônus set Guarda 3/3 | +15% HP | +15% HP **e +10 DEF** | GDB |
| N3 | Stun do Terremoto (R) | 1,5 s | 1,2 s / 1,6 s por nível | GDB |
| N4 | Dano da zona fora do círculo | 1% HP/s, +1%/s a cada 30 s | 1% → 5% HP/s, +1% por minuto (tabela §7.1) | GDB |
| N5 | Rolamento (E) | 4 u | 4,2 u em 0,35 s | GDB |
| N6 | Nível farmando só a base | "~7–8" | "~5" (§5.2) | GDB |
| N7 | Respawn fase 1 | 8 s | 8,0 s | iguais |
| N8 | Set épico | "épico só cai do boss e pertence ao conjunto sorteado" | baús raros têm 10% de épico | GDB — **confirmado pelo PI em 2026-10-09** |

## Decisão

- Para **números e fórmulas**, o `GDB.md` é a fonte. O `PRD.md` permanece fonte de **escopo, decisões (D1–D10), marcos e riscos**.
- `CONVENTION.md` cita o GDB; não repete tabelas, aponta a seção.
- Toda divergência nova vai para a tabela acima (ou para `RASTREABILIDADE.md` quando é de requisito, não de número) antes de virar código.
- O Code não "corrige" PRD nem GDB: registra em `[FIX]` ou pergunta ao PI (caso 1 de bloqueio do `GITHUB.md`).

## Consequências

- O PRD fica desatualizado em N1–N6 até o PI revisá-lo. Isso é aceitável: o PRD é lido por intenção, o GDB por valor.
- Os Resources `.tres` em `shared/data/` são gerados a partir do GDB §8; qualquer número no código que não esteja num `.tres` é defeito (`CLAUDE.md`, regra "valores de balanceamento em Resources").
- N8 é a única divergência de **regra**, não de número: fica como pendência do PI em `RASTREABILIDADE.md` (R-PEND-01).
