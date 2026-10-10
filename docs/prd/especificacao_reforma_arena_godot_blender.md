# Especificação Técnica de Reforma da Arena: Ilha Flutuante Arcana (Godot 4 & Blender)

**Projeto:** MOBA de 2 Tempos (`rrb-godot`)  
**Data:** 10 de outubro de 2026  
**Documentos Relacionados:** `PRD.md`, `GDB.md`, `guia_melhorias_graficas_godot4.md`  
**Referência Visual:** `full_high_resolution_panoramic_wide_battleground_view_of_the_stylized_3d_low.png`  
**Status:** Aprovado para Planejamento e Implementação Técnica

---

## 1. Visão Geral e Comparativo da Transformação

A imagem de referência estabelece uma mudança profunda de direção de arte para a arena:
* **Antes (Protótipo M1):** Arena plana em ladrilhos hexagonais amarelos/verdes, paredes cinzas duras e rio azul estático sobre um fundo cinza infinito.
* **Nova Visão (Ilha Flutuante Arcana):** Uma ilha mágica suspensa em um abismo cósmico/etérea, com castelos fortificados nas bases, rios de mana turquesa incandescente desaguando em cachoeiras no vazio, cristais arcanos e uma cratera vulcânica de obsidiana/magma no centro (o covil do Boss).

```
========================================================================================
                  MAPEAMENTO DA NOVA ARENA COM AS REGRAS DO PRD / GDB
========================================================================================

                 [ BASE 1: CASTELO NOROESTE ]            [ BASE 2: CASTELO NORDESTE ]
                 - Portão de Ferro/Madeira Seguro        - Portão de Ferro/Madeira Seguro
                 - 4 Esqueletos T1 + 1 Guerreiro T2      - 4 Esqueletos T1 + 1 Guerreiro T2
                 - 6 Baús Comuns                         - 6 Baús Comuns
                                  \                         /
                                   \                       /
                [ CAMPO LATERAL OESTE ]                 [ CAMPO LATERAL LESTE ]
                - 2 Esqueletos T1 + 1 T2                - 2 Esqueletos T1 + 1 T2
                - 2 Baús Laterais                       - 2 Baús Laterais
                - Cristais Mágicos / Moitas             - Cristais Mágicos / Moitas
                                        \             /
                                         \           /
               =============================================================
                           [ CENTRO CONTESTADO: CRATERA CENTRAL ]
                           - Fosso de Obsidiana e Magma Incandescente
                           - Spawn do Rei Esqueleto (Boss, 3:30 min)
                           - 2 Esqueletos Magos + 2 Golems de Pedra
                           - 4 Baús Raros ao redor do anel
                           - Centro da Zona da Fase 2 (Raio 35u -> 3.5u)
               =============================================================
                                         /           \
                                        /             \
                [ CAMPO LATERAL SUDOESTE ]              [ CAMPO LATERAL SUDESTE ]
                - 2 Esqueletos T1 + 1 T2                - 2 Esqueletos T1 + 1 T2
                - 2 Baús Laterais                       - 2 Baús Laterais
                                  /                         \
            [ CACHOEIRAS ARCANAS NO ABISMO ]       [ CACHOEIRAS ARCANAS NO ABISMO ]
            - Desague de energia no vazio           - Desague de energia no vazio
```

---

## 2. Decomposição de Zonas e Compatibilidade de Gameplay

Para que a nova estética não quebre as métricas balanceadas no **PRD §3.1** e **GDB §1.1**, as seguintes dimensões espaciais devem ser rigorosamente preservadas no Blender:

| Elemento do Mapa | Dimensão / Métrica | Função no GDB / PRD |
|---|---|---|
| **Distância Base -> Centro** | ~45 a 50 metros (~8.0s de caminhada) | Garante o tempo de rotação inicial do farm para contestar o centro. |
| **Diâmetro Total da Ilha** | ~80 a 90 metros | Arena completa atravessável em ~18 a 22s. |
| **Cratera Central (Covil do Boss)** | Raio de ~7.0m (diâmetro 14m) | Comporta a área de ataque do Golem (2.5u) e do Rei Esqueleto (5.0u). |
| **Pontes de Pedra (4 conexões)** | Largura mínima de 3.5m | Permite a passagem do Cavaleiro (colisão ~0.8m) sem prender bots nem a skill Q (Investida). |
| **Círculo da Zona (Fase 2)** | Centro exato no núcleo de magma | Encolhe de Raio 35.0u até 3.5u (o círculo final engloba exatamente o fosso central). |
| **Bordas da Ilha** | Paredes de colisão invisíveis (`-colonly`) | Impede que jogadores e monstros caiam no abismo involuntariamente. |

---

## 3. Pipeline de Modelagem no Blender

Em vez de importar dezenas de blocos hexagonais individuais no Godot, a arena será modelada em **kits modulares otimizados** no Blender e montada em uma cena principal.

### 3.1 Kit Modular no Blender (`art/arena/`)

1. **Ilha Base (`island_chassis.blend`):**
   * Malha contínua única para o solo transitável com bordas rochosas irregulares que caem em penhascos verticais.
   * Modelagem de sulcos para o leito do rio e a cavidade da cratera central.
2. **Kit Castelo / Base (`castle_modular.blend`):**
   * Torre redonda com ameias e topo plano.
   * Muralha reta e muralha em curva com passadiço.
   * Portal de entrada com detalhes em arco de pedra e portão de madeira reforçada com ferragens.
   * Tubulações arcanas e ranhuras para runas emissivas cianas/magentas nas paredes.
3. **Kit Cratera Central (`volcanic_crater.blend`):**
   * Pilares pontiagudos de obsidiana preta/cinza escura ao redor do fosso.
   * Malha côncava para o lago de magma com textura/shader separado.
4. **Kit Pontes e Ruínas (`ruins_bridges.blend`):**
   * Ponte de pedra em arco com degraus suaves (inclinação < 25° para o `CharacterBody3D` não escorregar).
   * Arcos de pedra antigos e pilares quebrados.
   * Barreiras de madeira e suportes rústicos para os campos laterais.
5. **Kit Props e Cristais (`props_crystals.blend`):**
   * Cristais facetados pontiagudos (conjuntos pequenos e grandes) para pontos de iluminação local.
   * Torres de vigia de madeira, balistas/canhões defensivos estilizados.
   * Pinheiros cônicos estilizados e moitas para a mecânica de visão (GDB §7.3).

### 3.2 Convenções de Exportação Blender -> Godot (`.glb`)

Para que o Godot crie a física automaticamente ao importar o `.glb`:
* **Pisos e Terreno:** Malha visual acompanhada de colisor tridimensional preciso com sufixo `-col` (ex: `IslandTerrain-col`).
* **Paredes, Muralhas e Rochas:** Usar colisor convexo com sufixo `-convcol` (ex: `CastleWall-convcol`).
* **Bordas do Abismo:** Malhas invisíveis verticais de contenção com sufixo `-colonly` (ex: `AbyssBarrier-colonly`).
* **Origem/Pivô:** Sempre na base inferior dos objetos (`Z=0` ou ponto de contato com o chão) para alinhamento rápido no editor.

---

## 4. Shaders Específicos para a Nova Arena

Para alcançar a fidelidade da imagem de referência, três shaders especializados devem ser criados na pasta `game/shaders/`:

### 4.1 Shader do Rio de Mana / Água Arcana (`arcane_river.gdshader`)
A água da referência não é natural, mas sim um fluido arcano emissivo que flui em direção ao abismo.

```glsl
shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_back;

uniform vec4 core_color : source_color = vec4(0.0, 0.95, 0.85, 0.9);   // Turquesa vibrante
uniform vec4 edge_color : source_color = vec4(0.05, 0.45, 0.75, 1.0);  // Azul profundo nas margens
uniform vec4 foam_color : source_color = vec4(0.85, 1.0, 0.95, 1.0);
uniform float flow_speed : hint_range(0.1, 2.0) = 0.6;
uniform float emission_strength : hint_range(0.5, 4.0) = 2.2;          // Faz a água brilhar no Glow

uniform sampler2D flow_noise : hint_default_white;
uniform sampler2D depth_texture : hint_depth_texture;

void fragment() {
	// Coordenadas UV em fluxo constante
	vec2 flow_uv = UV + vec2(0.0, -TIME * flow_speed * 0.1);
	float noise_val = texture(flow_noise, flow_uv).r;

	// Efeito de profundidade via buffer
	float raw_depth = textureLod(depth_texture, SCREEN_UV, 0.0).r;
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, raw_depth);
	vec4 view_coords = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view_coords.xyz /= view_coords.w;
	float water_depth = -view_coords.z - VERTEX.z;

	// Gradiente entre centro de energia e margem
	vec4 water_col = mix(edge_color, core_color, noise_val * 0.7 + 0.3);

	// Espuma luminosa de contato com margens e pedras
	float foam = clamp(1.0 - (water_depth / 0.25), 0.0, 1.0);
	vec3 final_color = mix(water_col.rgb, foam_color.rgb, foam * 0.85);

	ALBEDO = final_color;
	EMISSION = core_color.rgb * (noise_val * 0.5 + 0.5) * emission_strength;
	ROUGHNESS = 0.1;
	SPECULAR = 0.5;
}
```

---

### 4.2 Shader da Cratera de Magma / Lava Central (`volcanic_lava.gdshader`)
Para o covil do Rei Esqueleto e centro do fechamento da zona:

```glsl
shader_type spatial;

uniform vec4 magma_bright : source_color = vec4(1.0, 0.75, 0.2, 1.0);  // Amarelo incandescente
uniform vec4 magma_dark : source_color = vec4(0.9, 0.2, 0.05, 1.0);    // Laranja/Vermelho fogo
uniform vec4 rock_crust : source_color = vec4(0.12, 0.1, 0.1, 1.0);    // Placas de rocha escura
uniform float pulse_speed : hint_range(0.2, 3.0) = 1.2;
uniform float emission_energy : hint_range(1.0, 5.0) = 3.5;

uniform sampler2D voronoi_cracks : hint_default_white;

void fragment() {
	vec2 uv_moved = UV + vec2(sin(TIME * 0.2), cos(TIME * 0.2)) * 0.02;
	float crack_val = texture(voronoi_cracks, uv_moved).r;

	// Pulso respiratório de calor
	float pulse = (sin(TIME * pulse_speed) + 1.0) * 0.5;
	vec3 lava_color = mix(magma_dark.rgb, magma_bright.rgb, pulse * 0.6 + crack_val * 0.4);

	// Separação entre rocha fria flutuante e fissuras de lava viva
	float is_lava = step(0.35, crack_val);
	vec3 final_albedo = mix(rock_crust.rgb, lava_color, is_lava);

	ALBEDO = final_albedo;
	EMISSION = lava_color * is_lava * emission_energy;
	ROUGHNESS = mix(0.9, 0.2, is_lava);
}
```

---

### 4.3 Shader dos Cristais Mágicos (`arcane_crystal.gdshader`)
Para os cristais pontiagudos de mana (magentas e verdes nas laterais):

```glsl
shader_type spatial;
render_mode blend_mix, depth_draw_opaque;

uniform vec4 crystal_color : source_color = vec4(0.85, 0.15, 0.85, 1.0); // Magenta padrão
uniform float fresnel_power : hint_range(1.0, 6.0) = 3.0;
uniform float emission_mult : hint_range(1.0, 5.0) = 2.8;

void fragment() {
	// Cálculo do efeito Fresnel (bordas iluminadas)
	float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), fresnel_power);

	ALBEDO = crystal_color.rgb * 0.5;
	EMISSION = crystal_color.rgb * fresnel * emission_mult;
	ROUGHNESS = 0.15;
	METALLIC = 0.1;
}
```

---

### 4.4 Skybox do Abismo Cósmico (`abyss_skybox.gdshader`)
Para substituir o fundo cinza pelo espaço profundo com estrelas e nebulosas visto na imagem:

```glsl
shader_type sky;

uniform vec3 space_color : source_color = vec3(0.03, 0.02, 0.08);
uniform vec3 nebula_purple : source_color = vec3(0.25, 0.08, 0.35);
uniform vec3 nebula_cyan : source_color = vec3(0.05, 0.18, 0.25);

void sky() {
	vec3 dir = EYEDIR;
	// Gradiente sutil simulando nebulosa profunda no horizonte
	float height = clamp(dir.y * 0.5 + 0.5, 0.0, 1.0);
	vec3 sky_gradient = mix(nebula_cyan, nebula_purple, height);
	
	COLOR = mix(space_color, sky_gradient, 0.45);
}
```

---

## 5. Iluminação e Composição Atmosférica

Para reproduzir o contraste vibrante da ilustração:

1. **Iluminação Direcional de Contraste:**
   * Sol Direcional com cor suave levemente quente (`Color(0.98, 0.95, 0.88)`), simulando uma fonte distante superior.
   * `light_energy = 1.15`, ângulo de 50° para projetar sombras nítidas das torres sobre o terreno.
2. **Pontos de Luz Emissivos (`OmniLight3D` locais):**
   * Uma luz alaranjada suave no centro do fosso de magma (`light_color = Color(1.0, 0.45, 0.1)`, alcance 12m).
   * Luzes púrpuras e cianas de baixa intensidade próximas aos aglomerados de cristais arcanos.
   * Tochas nos portões das fortalezas para guiar visualmente o jogador de volta à base.
3. **Pós-Processamento com Glow e SSAO:**
   * `SSAO` configurado com raio de 1.8m para escurecer as fendas entre as rochas e as fundações do castelo.
   * `Glow` ativado em modo `Additive` com threshold `1.1`: faz as runas das muralhas, a lava central e o rio brilharem sem ofuscar os heróis.

---

## 6. Efeitos Visuais Ambientais (VFX da Arena)

1. **Cachoeiras de Mana no Abismo (`GPUParticles3D`):**
   * Onde o rio atinge a borda da ilha, colocar uma malha vertical com shader de cascata somada a um emissor de partículas de spray turquesa caindo no vazio.
2. **Brasas Flutuantes no Centro Vulcânico:**
   * Pequenas fagulhas lentas de fogo subindo do poço de magma (vida útil 3.0s, gravidade negativa suave).
3. **Ilhotas Secundárias de Fundo:**
   * Posicionar 3 a 5 pequenas ilhas rochosas flutuantes ao fundo (fora da área navegável, sem colisão) com algumas ruínas ou pinheiros para criar senso de profundidade e escala.

---

## 7. Roteiro Passo a Passo de Execução

| Etapa | Ferramenta | O que fazer | Entregável / Arquivo |
|:---:|:---:|---|---|
| **Passo 1** | **Blender** | Criar o *Greybox* com a silhueta da ilha flutuante, posicionando as duas bases, o rio e o covil central com as métricas exatas do PRD. | `art/arena/arena_greybox.blend` |
| **Passo 2** | **Blender** | Modelar os módulos do castelo, pontes de pedra, rochedos e cratera vulcânica. Adicionar colisores `-col` e `-convcol`. Exportar em `.glb`. | `game/assets/arena/arena_mesh.glb` |
| **Passo 3** | **Godot 4** | Criar os shaders da água arcana, lava central, cristais e skybox do abismo. | `game/shaders/*.gdshader` |
| **Passo 4** | **Godot 4** | Montar a nova cena `arena_island.tscn`, substituindo o grid hexagonal. Aplicar materiais e iluminação de contraste. | `game/scenes/arena/arena_island.tscn` |
| **Passo 5** | **Godot 4** | Ajustar o `NavigationRegion3D` e fazer o bake da nova malha de navegação (garantindo que bots e monstros cruzem as pontes sem travar). | `NavigationMesh` assado |
| **Passo 6** | **Godot 4** | Reatrelar os spawners de monstros, baús e o trigger da zona ao novo cenário. Testar com o Cavaleiro e Arqueira. | Validação da Fatia Vertical |
