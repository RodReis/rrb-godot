# SPEC-030 — Balanceamento dos 11 heróis antes do playtest, por soak cruzado

**Fatia:** F30 / SPEC-030 (MVP4, Slice 4.2) · **Issue:** #254 (issue-pai #246) · **Status:** decidida pelo PI em 2026-10-23 (pop-ups do Cowork: "Antes do playtest"; "40–60 %")
**ADR:** ADR-0004 (o GDB vence) · **Fontes:** GDB §1.1 e §4; `tools/soak.ps1`; `FORA-DE-ESCOPO.md` (linha "Ajuste dos números dos heróis 7–10"); comentários de encerramento de #202, #203, #214, #215 e #248
**Escopo:** só números em `shared/data/heroes/*.tres` (e nos Resources de habilidade que eles referenciam). Mecânica, código de jogo, IA do bot e contrato não mudam.

## 1. Motivo

Nos soaks fora do espelho, o Berserker venceu 44/44, o Paladino 33/45, o Ocultista 8/45 e o Protetor 13/43. Jogar o playtest assim contamina o critério de snowball e a vontade de jogar de novo (PRD §9.2). O PI decidiu ajustar **antes** do playtest, com dado de soak. Se o playtest pedir mais ajuste, isso vira fatia nova, com número novo.

## 2. Medição

1. **Soak cruzado:** `.\tools\soak.ps1` com os 11 heróis, nível de bot padrão (Médio) nos dois lados, seed fixa e registrada. Conta só partida **fora do espelho** (herói A ≠ herói B).
2. **Amostra:** pelo menos 45 partidas fora do espelho **por herói** (mesma ordem de grandeza dos soaks anteriores). O Code calcula o `-Count` e registra.
3. **Taxa de vitória** de cada herói = vitórias ÷ partidas fora do espelho. Partida sem vencedor (empate, timeout do soak) não entra no denominador e é contada à parte.
4. **Linha de base** antes de qualquer mudança, com o mesmo comando e a mesma seed.

## 3. Alvo

- Cada herói entre **40 % e 60 %** de vitória no soak cruzado.
- Com ~45 partidas a margem é de ±15 pontos; um herói fora da faixa por poucos pontos é reavaliado com amostra maior antes de mexer.
- O soak mede o **bot** pilotando o herói. Se o desvio de um herói vier da IA (ex.: o bot não usa uma habilidade), o Code **não** compensa com número: registra no PR e abre `[FIX]` do bot. Nesse caso, o herói pode fechar a fatia fora da faixa, com o motivo escrito.

## 4. Entrega

1. Ajustes só em `.tres`, um herói por commit quando possível.
2. Teste GUT que trava número de herói (se houver) é atualizado no mesmo commit.
3. Na PR: tabela antes/depois de cada número alterado, por herói, e a tabela de taxa de vitória (linha de base × final), com o comando e a seed.
4. Evidência em `docs/evidencias/f30/` (relatórios do soak).
5. O GDB §4 é alinhado aos `.tres` pelo Cowork depois do aceite do PI (ADR-0004: o GDB é a fonte dos números).

## 5. Critério de aceite

1. Soak final com os 11 heróis e a amostra do §2, sem travar (verde).
2. Todo herói entre 40 % e 60 %, ou fora com motivo de IA registrado e `[FIX]` aberto.
3. Suítes `game` e `launcher` verdes; CI verde.
4. Aceite do PI pelos números (tabela da PR).

## 6. Fora

Mecânica nova, IA do bot, Rei Esqueleto e campos (linha própria no `FORA-DE-ESCOPO.md`), ajuste com dado de playtest (fatia nova, se preciso).
