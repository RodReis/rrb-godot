# Roteiro F10 — baús, inventário e conjuntos

Servidor com seed fixa, para os drops serem sempre os mesmos:

```powershell
.\tools\run-server.ps1 -Seed 37
.\tools\run-clients.ps1 -Count 1
```

O log do servidor imprime `[spawn] seed dos baus 37`. Com a seed 37, a base A (primeiro peer a conectar) tem: Arma Comum, Elmo, Peitoral e Botas da Guarda (comuns) e 2 curas. O centro tem: 2× Arma Rara, Botas do Caçador (Raro) e Elmo da Guarda (Comum).

| # | Passo | Esperado |
|---|---|---|
| 1 | Na base, tocar F a ≤ 1,5 u de um baú marrom | Tampa abre; o item vai para o slot vazio (lista no canto superior esquerdo) |
| 2 | Tocar F de novo no mesmo baú | Nada: baú aberto não reabre |
| 3 | Abrir os 3 baús da Guarda | `conjunto guard 3/3`; HP máx × 1,15 (Nv 3: 740 → 851) |
| 4 | Baú de cura com o herói ferido | +120 HP, limitado ao HP máx |
| 5 | Centro, baú azul com Arma Rara | Troca a Arma Comum sozinha (raridade maior) |
| 6 | Baú azul com Botas do Caçador (Raro) | Troca sozinha; o conjunto cai para `guard 2/3` e o HP máx desce |
| 7 | Baú com o 2º item de raridade igual (Arma Rara ou Elmo comum) | Item fica no baú com "segure F para trocar" |
| 8 | Segurar F desde a abertura | Não troca |
| 9 | Soltar o F e segurar de novo por 0,4 s | Troca; o item antigo some; o rótulo do baú some |

Verificado pelo PI em 2026-10-09: passos 1 a 6 (capturas: Nv 3 740, Nv 5 830, Guarda 3/3 851).
