# Roteiro F12 — bot da fase 1 e modo offline (host)

## Aceite headless (Code)

```powershell
$cli = $env:GODOT_PATH -replace '\.exe$','_console.exe'
& $cli --headless --path game -- --offline --bot   # encerrar depois de ~5:10
```

O log mostra:
- a porta efêmera (`[server] escutando em 127.0.0.1:<porta>`);
- o navmesh (`[bot] navmesh: <n> poligonos`);
- as transições da FSM (`[bot] FARM -> LOOT (Nv 2, 190 XP)` …);
- no fim da fase 1, o nível de cada herói (`[match] bot 2: Nv 5, 935 XP`).

| Rodada (2026-10-09) | Commit | Resultado |
|---|---|---|
| 1 | `c38cb3d` | Base limpa (225 XP, Nv 3) → saqueia → centro (Nv 5, 935 XP) → contesta às 3:00 → **mata o Rei** → **Nv 6, 1485 XP**; 0 `ERROR`/`WARN` |
| 2 | `9d92518` | Mesmo caminho até **Nv 5, 935 XP**; contra o Rei alterna contestar ↔ recuar, e o boss volta com HP cheio pelo leash; 0 `ERROR`/`WARN` |

## Com janela (PI)

```powershell
& $env:GODOT_PATH --path game -- --offline --bot
```

| # | Passo | Esperado |
|---|---|---|
| 1 | Abrir | Status `offline (host) \| tick … \| 0:0x`; você é o Cavaleiro do time A, sem conectar em nada |
| 2 | Olhar a base B (lado oposto) | O bot contorna muros e rio e mata os 5 monstros da base dele |
| 3 | Esperar | Ele abre os 6 baús da base e vai ao centro |
| 4 | 3:00 | Com nível ≥ ao seu, ele vai atrás do Rei Esqueleto |
| 5 | Chegar perto dele com nível menor | Ele luta com você; com HP < 30 % e perigo perto, recua para a base |
| 6 | Ficar no seu pátio, atrás do portão A | O bot não empurra o portão; para do lado de fora |
