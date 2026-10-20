# Briefing para artista 3D — Cavaleiro (Loot Start)

**Projeto:** Loot Start — jogo de arena PvP 3D para PC, em terceira pessoa, feito no Godot 4.7.
**Contato:** Rodrigo Reis (contratante). **Data:** 2026-10-19.
**Uso deste personagem:** teste de direção visual (spike, `SPEC-093`). Se aprovado, o estilo vira referência para os outros heróis e para skins.

> Preço, prazo, forma de pagamento e direitos de uso e modificação são combinados diretamente com o contratante. Este documento descreve só o trabalho.

## 1. O personagem

- **Cavaleiro**, classe Tanque, corpo a corpo. Espada de uma mão + escudo.
- Em jogo ele investe para frente (Q), levanta um escudo/muralha (E) e dá um golpe forte no chão (R).
- Silhueta pesada e legível a distância: o jogador vê o herói de cima, a cerca de 11 m, câmera a ~45°.

## 2. Estilo

- **Referência: Eternal Return** — personagens semi-realistas, proporções próximas do real com leve estilização, rosto expressivo, materiais PBR com bom detalhe de tecido, metal e couro.
- **Design original.** Não copiar nenhum personagem ou asset de Eternal Return ou de outro jogo; é referência de acabamento e proporção.
- Fantasia medieval; armadura de placas com partes de tecido/couro. Sem cel-shading nem contorno.

## 3. Especificação técnica

| Item | Valor |
|---|---|
| Triângulos | até 6.000 (personagem + espada + escudo) |
| Texturas | PBR metallic-roughness, até 2048×2048: cor base, normal, ORM (oclusão, roughness, metal) |
| Materiais | 1 ou 2 |
| Escala | 1 unidade = 1 metro; altura do personagem coerente com uma cápsula de colisão de 1,8 m de altura e 0,4 m de raio |
| Orientação | Y para cima; personagem olhando para +Z; pés na origem (0,0,0) |
| Rig | esqueleto humanoide com nomes de ossos claros (convenção humanoide padrão, ex.: Hips, Spine, Chest, Neck, Head, LeftUpperArm…); compatível com exportação glTF 2.0 |
| Pontos de fixação | ossos ou empties dedicados para mão direita (arma) e antebraço/mão esquerda (escudo), nomeados (ex.: `hand_r_slot`, `hand_l_slot`) |
| Malha | sem n-gons na exportação, normais limpas, sem faces internas |

## 4. Entregáveis

1. `knight_er.glb` (glTF 2.0 binário) com malha, rig, materiais, texturas embutidas e as animações do §5.
2. Arquivo fonte `.blend` (Blender 4.x/5.x) com o mesmo conteúdo.
3. Texturas também em arquivos separados (PNG).
4. 3 renders de apresentação: frente, costas e vista de cima a ~45°, a ~11 m.

## 5. Animações (8)

Todas em 30 fps, **no lugar** (sem root motion), nomes exatamente como abaixo.

| Nome do clipe | Ação | Laço |
|---|---|---|
| `Idle` | parado, respiração | sim |
| `Run` | corrida normal (~5,8 m/s) | sim |
| `Dash` | investida para frente (usada no Q) | sim |
| `Block` | escudo levantado, postura de defesa (E) | sim |
| `Stunned` | atordoado / tomou golpe forte | não |
| `Attack_Basic` | golpe horizontal de espada, ~0,8 s | não |
| `Attack_Slam` | golpe forte para baixo no chão (R) | não |
| `Death` | morte, termina deitado | não |

## 6. Como vamos verificar

O personagem entra numa cena de teste jogável do jogo. Checamos: escala contra a cápsula, orientação, cada animação no momento certo, pés sem deslizar na corrida, leitura da silhueta a 11 m e desempenho.
