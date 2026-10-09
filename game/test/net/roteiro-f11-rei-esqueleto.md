# Roteiro F11 — Rei Esqueleto, baú épico e relógio da partida

Servidor com o relógio adiantado e o herói forte o bastante para matar o boss:

```powershell
.\tools\run-server.ps1 -Seed 37 -Level 8 -Time 200
.\tools\run-clients.ps1 -Count 1
```

O relógio começa no 1º peer. Com `-Time 200` ele já começa em 3:20, então o aviso das 3:00 sai na hora e o boss aparece ~10 s depois. O log do servidor imprime `[match] aviso do boss`, `[match] fim da fase 1` e `[match] Rei Esqueleto morto por <peer>`.

| # | Passo | Esperado |
|---|---|---|
| 1 | Olhar o status no topo | `… \| tick … \| 3:2x`, contando |
| 2 | 3:30, ir ao centro da cratera | Rei Esqueleto (~3 u, coroa dourada), `2400 / 2400` |
| 3 | Chegar a ≤ 3 u | Golpe em área a cada 1,4 s tira HP e empurra ~2,5 u, num deslize curto, sem tranco |
| 4 | Afastar o boss mais de 8 u do centro | Ele volta e regenera o HP |
| 5 | Matar o boss | XP sobe 550; surge um baú dourado onde ele caiu |
| 6 | Tocar F no baú dourado | Um dos 7 épicos é equipado sozinho |
| 7 | 5:00 | Os dois portões das bases caem |

Verificado pelo PI em 2026-10-09:
- passos 1, 2, 3, 5, 6 e 7: XP 3375 → 3925, Elmo do Caçador (Épico), portões caídos às 5:56;
- 1ª rodada: tranco a cada golpe do boss, porque o empurrão era só do servidor;
- 2ª rodada, com a correção `83e3647`: "sem lag, rodando liso".
