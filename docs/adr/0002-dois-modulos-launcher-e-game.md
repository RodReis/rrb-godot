# ADR-0002 — Dois módulos independentes: Launcher e Game

**Status:** aceito — 2026-10-08
**Decisor:** Rodrigo Reis (PI)
**Relacionados:** [ADR-0003](0003-shared-por-junction.md), [ADR-0004](0004-gdb-vence-numeros.md), PRD §8, `DESIGN-VISUAL-LAUNCHER.md`

## Contexto

O PRD §8.2 define "um projeto Godot, dois papéis" (cliente e servidor dedicado). O documento de design visual especifica 9 telas, das quais 5 não participam da partida (lobby, bestiário, forja, configurações, histórico) e 4 participam (seleção de heróis, HUD fase 1, HUD fase 2, fim de partida). O `CLAUDE.md` original falava em "interface web" para o launcher — resíduo de template de outro projeto, não decisão do PI.

O PI quer os dois lados desenvolvidos **sem que um amarre o outro**: build, testes, CI e ordem de implementação separados.

## Decisão

1. **Dois projetos Godot no mesmo monorepo:** `game/` (partida: cliente + servidor dedicado headless) e `launcher/` (tudo fora da partida). Cada um tem `project.godot`, export presets, testes GUT e job de CI próprios.
2. **Launcher em Godot, não web.** Mesmo stack, mesmo Theme, mesmos Resources. Nenhum segundo design system.
3. **Backend NestJS pertence ao módulo Launcher.** O Game só consome dois endpoints internos (validar token, reportar resultado). `ARCHITECTURE-LAUNCHER.md` cobre launcher e backend.
4. **Seleção de Heróis e Fim de Partida são do Game.** Têm estado de partida (timer de pick, escolha do oponente, estatísticas do servidor). O Launcher recebe só o resumo final, pelo backend.
5. **Código comum vive em `shared/`** (Resources `.tres`, regras puras, Theme, assets 3D), montado nos dois projetos por junction — ver ADR-0003.
6. **Contrato entre módulos é mínimo e explícito:** processo + argumentos de linha de comando (Launcher → Game), HTTP (ambos → Backend), arquivo de configuração compartilhado em `user://` (ver `ARCHITECTURE-LAUNCHER.md` §5). Nenhum dos dois importa cena ou script do outro.

## Alternativas descartadas

| Alternativa | Por que não |
|---|---|
| Um projeto Godot com pastas `launcher/` e `match/` | Independência só por disciplina; um erro de parse em qualquer lado quebra o outro; export único carrega UI do lobby no servidor headless. |
| Launcher web (React + Tauri/Electron) | Segundo stack completo, dois design systems, IPC com o executável, handoff de token. Não valida nenhum risco R1–R8 do PRD. Dev solo em 15 semanas não paga esse custo. |
| Backend como terceiro módulo | Mais um documento de arquitetura para um backend "fino" (PRD D10). Pode ser promovido depois sem mudar código. |

## Consequências

- **Positivas:** CI por módulo; o Game pode avançar M0–M2 sem uma linha de launcher; o launcher pode ser reescrito (até em web, na fase B) sem tocar no Game; o servidor headless não carrega nada de lobby.
- **Negativas / custos:** dois `project.godot` para manter; `shared/` é um ponto de acoplamento (mudança nele dispara CI dos dois); dois executáveis para distribuir (launcher lança o game por processo); a cena de alinhamento de assets (PRD §11) fica em `shared/` e precisa abrir nos dois editores.
- **Independência é de build/CI/ordem, não de calendário:** o risco R8 do PRD ("nada paralelo", dev solo) continua. O PI sequencia os módulos; hoje a ordem é Game (M0–M2) → Launcher + Backend (M3).
- `ARCHITECTURE-GAME.md` e `ARCHITECTURE-LAUNCHER.md` são os documentos normativos de cada módulo; `CONVENTION.md` é comum aos dois.
