# SPEC-045 — Câmera: giro 360° com o botão esquerdo segurado; ataque básico no botão direito

**Fatia:** F45 / SPEC-045 (MVP2.5, Slice 2.5.7 — **1º card do marco**, antes do F38) · **Issue:** #103 · **Status:** decidida pelo PI em 2026-10-10 ("giro no botão esquerdo"; "mecânica padrão para este tipo de game"; "melhora a mecânica junto com o WASD")
**Supera:** decisão B-02/F31 de **yaw fixo do time** (`STATUS-ARQUIVO.md`, 2026-10-09) — o yaw inicial continua o do time, mas passa a ser livre depois; PRD §3.6 e DV §3.3 na linha do ataque básico (botão esquerdo → direito); issue #47 (giro no botão direito), fechada como substituída.
**Fontes:** PRD §3.6 · `CONVENTION.md` §6 · DV §3.3 · `RASTREABILIDADE.md` P-16, P-17, V-20 · `game/scripts/follow_camera.gd`, `game/scripts/core/camera_rig.gd`, `game/scripts/net/player_input.gd`, `shared/core/input_actions.gd`
**Escopo:** só cliente. O servidor, o rollback e o bot não mudam. O input já vai em coordenadas de mundo (`movement` pelo yaw da câmera, `aim` por raio do cursor ao chão).

## 1. Motivo

- O PI quer ver as áreas que pilares e muros escondem (V-20) girando a câmera, e avalia que o giro melhora o controle junto com o WASD, que já é relativo à câmera.
- O botão esquerdo era o ataque básico (`primary_attack`) com ataque contínuo enquanto segurado. Por isso o ataque vai para o botão direito, que é o padrão dos MOBAs de mira por cursor (decisão do PI: "mecânica padrão para este tipo de game").

## 2. Mapeamento (teclado e mouse)

| Ação (`InputActions`) | Antes | Depois |
|---|---|---|
| `primary_attack` | botão esquerdo | **botão direito** — segurar = ataque contínuo, como hoje |
| `camera_orbit` (**nova**) | — | **botão esquerdo segurado** |

O gamepad não muda: o analógico direito continua só mirando e o ataque continua no RT/R2.

## 3. Comportamento da câmera

1. **Início da partida:** o yaw inicial continua o do time (olhando o centro a partir do spawn, F31).
2. **Girar:** com `camera_orbit` segurado, o movimento horizontal do mouse muda o yaw em volta do herói, 360° sem limite. A inclinação (45°) e a distância (14 u) não mudam.
3. **Cursor durante o giro:** fica oculto e capturado (`Input.MOUSE_MODE_CAPTURED`). Ao soltar, volta visível na posição em que estava antes do giro. A mira mantém o último valor enquanto o botão está segurado.
4. **Soltar:** a câmera fica no ângulo em que parou. Não há retorno automático ao yaw do time.
5. **HUD:** clique em controle da HUD (`Control` que consome o evento) não inicia o giro. O giro é tratado em `_unhandled_input`.
6. **WASD:** sem mudança de código. Continua `CameraRig.to_world(v, yaw)` com o yaw atual da câmera, então W é sempre "para longe da câmera".
7. **Sensibilidade:** um `@export` na câmera, com valor inicial ajustado na verificação visual do PI. A tela de controles do launcher (F24) não ganha opção de sensibilidade por esta spec.

## 4. Implementação

- `shared/core/input_actions.gd`: `CAMERA_ORBIT` em `MOUSE_BUTTONS` (`MOUSE_BUTTON_LEFT`); `PRIMARY_ATTACK` → `MOUSE_BUTTON_RIGHT`. Nome novo também em `CONVENTION.md` §6.
- `game/scripts/core/camera_rig.gd`: função pura de giro (yaw + delta do mouse × sensibilidade, normalizado em `[-PI, PI)`), com teste GUT.
- `game/scripts/follow_camera.gd`: mantém a trava inicial do yaw do time; depois aplica o giro enquanto `camera_orbit` estiver pressionado; captura e restaura o cursor.
- HUD: rótulo da tecla do ataque básico `LMB` → `RMB` em `hud_phase1` e na `_gallery`.
- Servidor headless: a câmera não existe nele; nada muda.

## 5. Critério de aceite do F45

1. GUT: função de giro (soma, sentido e normalização do yaw); mapeamento padrão (`primary_attack` = direito, `camera_orbit` = esquerdo); segurar o esquerdo não liga `attack` no `PlayerInput`.
2. GUT: com yaw girado, `CameraRig.to_world` continua levando W para longe da câmera (regressão do movimento).
3. Treino offline vs bot e 2 clientes contra servidor local: girar não muda nada no servidor (sem `past the history limit`; movimento e mira consistentes depois do giro).
4. Lint e CI verdes. Verificação visual do PI (girar 360°, andar com WASD depois do giro, atacar com o direito, cursor volta ao lugar) + vídeo curto no roadmap.

## 6. Fora desta spec

- Silhueta do herói através de parede / obstáculo transparente (V-20, card #70) — continua aberto; o giro ajuda mas não resolve oclusão em combate.
- Giro pelo gamepad; zoom; retorno automático ao yaw do time; tecla de recentralizar; opção de sensibilidade no launcher.
- Minimapa (F37): esta spec não decide se gira com a câmera.
