# Roteiro F16 — peer desconectado morre pela zona (SPEC-016, #63)

Risco herdado do MVP0 (`MVP-2.md`): com `enable_prediction=false` o netfox para de simular o herói sem input, que ficaria imune à zona. O F15 passou a sintetizar input vazio no servidor (`Hero.mark_disconnected`); aqui se prova que a zona do F16 mata esse herói.

## Como rodar

```powershell
$cli = $env:GODOT_PATH -replace '\.exe$','_console.exe'
& $cli --headless --path game --log-file <pasta>\server.log -- --server --port=7000 --seed=16 --time=500
.\tools\run-clients.ps1 -Autopilot -LogDir <pasta>
# heróis nascem (~25 s de seleção); fechar o processo do 2º cliente
```

- `--time=500`: a fase 1 começa em 8:20, então a fase 2 já está correndo quando os heróis nascem (zona com ~5 u de raio, 4 %/s).
- O servidor precisa de `--log-file`: com stdout redirecionado para arquivo o Godot no Windows segura a saída em buffer e o log fica parado.

## Execução — 2026-10-10 (local, sem netem)

Log filtrado: `f16-logs/zona-desconectado-server.log`.

```
[server] peer 2018575930 saiu
[match] heroi 2018575930 segue simulado com input vazio do servidor
[net] heroi 2018575930 desconectado: tick 1279, HP 436/600, pos (26.6, -22.2)
[net] heroi 2018575930 desconectado: tick 1430, HP 272/600, pos (26.6, -22.2)
[net] heroi 2018575930 desconectado: tick 1579, HP 108/600, pos (26.6, -22.2)
[match] heroi 2018575930 morto por 0, tick 1680
[net] heroi 2018575930 desconectado: tick 1880, HP 600/600, pos (24.0, -24.0)
[match] PHASE2 -> SUDDEN_DEATH, tick 2068
[match] heroi 1453828230 morto por 0, tick 2462
[match] fim: elimination, vencedor 2018575930, placar { ... }, tick 2462
```

Resultado: **o herói desconectado perde HP pela zona e morre** (`morto por 0` = sem herói matador). Renasceu antes das 9:00 (respawn ainda ligado), e na morte súbita quem morreu primeiro foi o outro herói, parado na base sem ninguém jogando — fim por eliminação. Servidor dedicado encerrou sozinho no fim.

Observações:

- Entre fechar o cliente e o ENet detectar a queda (`peer saiu`), o servidor não recebe input daquele herói e não o simula: nessa janela de alguns segundos ele não toma dano. Depois da queda volta a ser simulado. Não muda o resultado; é o tempo de detecção do ENet.
- Perda de HP acima dos 4 %/s da zona antes da 1ª morte: o herói estava perto de um campo e também apanhava de monstro.

## Fim chega aos clientes — 2026-10-10 (`--time=590`, colapso logo após nascer)

Depois da revisão (servidor saía no mesmo quadro do `match_ended`, e sair descarta a fila do ENet), o servidor dedicado espera 2 s antes de `quit(0)`. Execução:

```
servidor saiu: True codigo 0
[match] fim: collapse_hp, vencedor 1070924700, placar { ... }, tick 1171   # servidor
[match] fim: collapse_hp, vencedor 1070924700, placar { ... }, tick 1171   # cliente 1
[match] fim: collapse_hp, vencedor 1070924700, placar { ... }, tick 1171   # cliente 2
```

## Verificação visual (PI) — offline vs bot, `--time=290 --level=6`

1. 5:00: portões caem; a borda vermelha da zona aparece no raio 35 e fecha.
2. Fora da borda a barra de HP cai a cada segundo; dentro não cai.
3. Morte pela zona mostra "VOCÊ FOI ABATIDO!" e o respawn da fase 2.

Feita pelo PI em 2026-10-10 (capturas `docs/roadmap/img/mvp2-f16-*.webp`).
