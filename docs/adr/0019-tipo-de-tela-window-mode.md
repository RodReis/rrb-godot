# ADR-0019 — Tipo de tela em `settings.cfg`: `window_mode` no lugar de `fullscreen`

**Status:** aceito — decisão do PI em 2026-10-19 (pedido direto, sem Cowork: o Code abriu a fatia F79 / SPEC-079, issue #226)
**Decisor:** Rodrigo Reis (PI)
**Emenda:** `ARCHITECTURE-LAUNCHER.md` §5.3 (contrato `user://settings.cfg`, ADR-0002) — chave `[video] fullscreen` substituída por `window_mode`
**Relacionados:** F24 (#80, nasceu o contrato) · F79 (#226) · [Godot 4.7 `Window.Mode`](https://docs.godotengine.org/en/4.7/classes/class_window.html)

## Contexto

O contrato do `settings.cfg` tinha `[video] fullscreen=bool`, aplicado como `Window.MODE_FULLSCREEN`. O PI pediu três tipos de tela: **Modo Janela**, **Janela sem Borda** e **Tela Cheia Exclusiva**. Um booleano não representa três estados, e `settings.cfg` é o contrato entre Launcher e Game (`ARCHITECTURE-LAUNCHER.md` §5): mudá-lo exige ADR.

## Decisão

1. **Chave nova:** `[video] window_mode = "windowed" | "borderless" | "exclusive"`.
   - `windowed` → `Window.MODE_WINDOWED`, `borderless=false`, resolução escolhida, centralizada.
   - `borderless` → `Window.MODE_FULLSCREEN` (cobre o monitor, sem decoração, sem trocar o modo de vídeo).
   - `exclusive` → `Window.MODE_EXCLUSIVE_FULLSCREEN` (janela única, menos overhead; pode piscar a tela no Windows).
2. **Compatibilidade:** o Launcher deixa de gravar `fullscreen`. Na leitura, `fullscreen` só vale quando `window_mode` está ausente: `true` → `borderless` (o comportamento que o jogador já tinha), `false` → `windowed`. `window_mode` com valor desconhecido → padrão. Quem já tem `settings.cfg` não perde o que escolheu.
3. **`schema` continua 1.** A mudança é aditiva e a leitura é tolerante; subir o `schema` faria o Game descartar todas as preferências de quem já salvou (`schema` diferente → padrões).
4. **Padrão sem arquivo: `borderless`** (decisão do PI, "padrão `fullscreen=true`"). Muda o primeiro boot de quem nunca abriu as Configurações: antes era janela.
5. **Resolução só vale em `windowed`.** Pela doc da 4.7, `MODE_FULLSCREEN` e `MODE_EXCLUSIVE_FULLSCREEN` **não trocam o modo de vídeo do monitor** e forçam a janela ao tamanho dele; nenhum dos dois usa a resolução escolhida. Nos dois modos de tela cheia o seletor fica desabilitado. O PI havia escolhido "Janela e Exclusiva usam a resolução" por uma descrição errada do Code (exclusiva como modo de vídeo real); a engine não faz isso. Resolução em tela cheia exigiria escala de render (`scaling_3d_scale`), fora da F79.
6. **Ao voltar para janela, `borderless=false`:** a doc 4.7 diz que entrar em tela cheia força `borderless=true`.
7. **Quem aplica:** `SettingsApplier.apply_video` (`shared/`), o mesmo código no Launcher e no Game. Linha de comando (`--resolution`/`--position`) continua mandando no Game.

## Consequências

- O primeiro boot de um instalador novo abre em tela inteira sem borda (decisão 4). Ferramentas de captura que instanciam o `App` sem `settings.cfg` herdam isso; as que precisam de janela fixa passam o tamanho pela linha de comando.
- `ARCHITECTURE-LAUNCHER.md` §5.3 e o teste de contrato em `shared/test/` passam a descrever `window_mode`.
- Não cobre escolha de monitor, Alt+Enter nem escala de render.
