# Especificação Técnica de Melhorias Gráficas e Visuais — Godot 4 & Blender

**Projeto:** MOBA de 2 Tempos (`rrb-godot`)  
**Data:** 10 de outubro de 2026  
**Autor:** Rodrigo Reis / Gemini Spark  
**Público-Alvo:** Desenvolvedor / Claude Opus 5.5 / Pipeline Godot-Blender  
**Status:** Pronto para Implementação Técnica

---

## 1. Visão Geral e Direção Artística (Stylized PBR)

O projeto utiliza a base modular low-poly das famílias **KayKit** e **Quaternius**, caracterizada por proporções estilizadas e heróis com traços simplificados. O objetivo de "tornar o gráfico mais realista" não consiste em aplicar texturas fotográficas (o que geraria descompasso estético), mas sim em atingir o padrão **Stylized PBR / High-End Stylized** (referências: *League of Legends: Wild Rift*, *Brawl Stars*, *Dota 2* e *Torchlight*).

### Pilares da Transformação
1. **Fidelidade de Luz e Volume:** Substituir a iluminação plana por iluminação física com sombras suaves, oclusão de contato (SSAO) e luz indireta (SSIL/SDFGI).
2. **Superfícies Reativas:** Eliminar cores sólidas uniformes através de shaders com variação procedural, profundidade de água, relevo de terreno e curvatura de bordas.
3. **Legibilidade e Impacto de Combate (VFX):** Partículas emissivas com bloom dinâmico, trilhas em projéteis, ondas de choque e marcas no chão (*Decals*).
4. **Interface Temática:** HUD estruturada com componentes estilizados (*NinePatchRect*), animações dinâmicas de impacto (*Ghost Bar*) e ícones de habilidades.

---

## 2. Setup de Iluminação e Pós-Processamento

As configurações a seguir devem ser aplicadas na cena principal da arena (`game/scenes/arena/arena.tscn`) nos nós `WorldEnvironment` e `DirectionalLight3D`.

### 2.1 Configuração do `WorldEnvironment`

| Propriedade | Seção / Campo | Valor Recomendado | Justificativa Técnica |
|---|---|---|---|
| **Tonemap Mode** | `Tonemap / Mode` | `ACES` ou `Filmic` | Mapeamento de tons cinematográfico; impede que brancos e magias saturem de forma plástica. |
| **Tonemap Exposure** | `Tonemap / Exposure` | `1.0` a `1.15` | Brilho geral balanceado sem queimar áreas claras. |
| **SSAO Enabled** | `SSAO / Enabled` | `True` | Gera sombras de contato sob pedras, bases dos hexágonos e personagens. |
| **SSAO Radius** | `SSAO / Radius` | `1.5 m` | Raio de propagação da oclusão compatível com a escala do herói (~1.8m). |
| **SSAO Intensity** | `SSAO / Intensity` | `2.0` | Sombra de contato bem delineada, eliminando o efeito de "objetos flutuando". |
| **SSIL Enabled** | `SSIL / Enabled` | `True` | Luz indireta na tela: a cor amarelada/verde do chão rebate na base das muralhas cinzas. |
| **SDFGI Enabled** | `SDFGI / Enabled` | `True` (ou `VoxelGI`) | Iluminação global dinâmica de campo; preenche sombras com luz ambiente coerente. |
| **Glow Enabled** | `Glow / Enabled` | `True` | Habilita o brilho das magias e runas. |
| **Glow Threshold** | `Glow / Threshold` | `1.05` | Apenas materiais com `emission_energy_multiplier > 1.0` emitirão brilho, preservando o cenário. |
| **Glow Blend Mode** | `Glow / Blend Mode` | `Additive` ou `Soft Light` | Mesclagem natural de partículas luminosas. |
| **Volumetric Fog** | `Volumetric Fog / Enabled` | `True` | Cria sensação de atmosfera e profundidade de ar na arena. |
| **Fog Density** | `Volumetric Fog / Density` | `0.008` | Densidade muito sutil para não prejudicar a visão tática da câmera a 45°. |

### 2.2 Configuração da Luz Solar (`DirectionalLight3D`)

```gdscript
# Parâmetros recomendados para DirectionalLight3D:
light_color = Color(1.0, 0.96, 0.88)  # Sol levemente dourado (tarde/manhã)
light_energy = 1.35
rotation_degrees = Vector3(-48.0, 38.0, 0.0) # Luz diagonal projetando sombras dinâmicas

shadow_enabled = true
shadow_bias = 0.04
shadow_blur = 1.8                     # Sombras suaves (não pixeladas/serrilhadas)
directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
directional_shadow_max_distance = 65.0
```

---

## 3. Shaders Prontos para o Cenário

### 3.1 Shader de Água Estilizada com Profundidade e Espuma (`game/shaders/water.gdshader`)

Substitui a malha azul lisa atual por um corpo de água dinâmico que detecta a profundidade do rio e gera espuma nas margens e rochas.

```glsl
shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 shallow_color : source_color = vec4(0.22, 0.65, 0.82, 0.85);
uniform vec4 deep_color : source_color = vec4(0.08, 0.28, 0.52, 0.95);
uniform float depth_distance : hint_range(0.1, 5.0) = 1.2;

uniform vec4 foam_color : source_color = vec4(0.95, 0.98, 1.0, 1.0);
uniform float foam_distance : hint_range(0.01, 1.0) = 0.18;

uniform sampler2D wave_normal1 : hint_normal;
uniform sampler2D wave_normal2 : hint_normal;
uniform vec2 wave_speed1 = vec2(0.03, 0.02);
uniform vec2 wave_speed2 = vec2(-0.02, 0.03);

uniform sampler2D depth_texture : hint_depth_texture, filter_linear_mipmap;
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

void fragment() {
	// Cálculo de profundidade via Depth Buffer
	float depth_raw = textureLod(depth_texture, SCREEN_UV, 0.0).r;
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth_raw);
	vec4 view_coords = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view_coords.xyz /= view_coords.w;
	float linear_depth = -view_coords.z;
	float water_depth = linear_depth - VERTEX.z;

	// Movimento de normais cruzadas
	vec2 uv1 = UV + wave_speed1 * TIME;
	vec2 uv2 = UV + wave_speed2 * TIME;
	vec3 n1 = texture(wave_normal1, uv1).rgb * 2.0 - 1.0;
	vec3 n2 = texture(wave_normal2, uv2).rgb * 2.0 - 1.0;
	vec3 final_normal = normalize(n1 + n2);

	NORMAL = final_normal;

	// Gradiente de cor por profundidade
	float depth_factor = clamp(water_depth / depth_distance, 0.0, 1.0);
	vec4 base_water = mix(shallow_color, deep_color, depth_factor);

	// Linha de espuma nas bordas do rio e pedras
	float foam_factor = clamp(1.0 - (water_depth / foam_distance), 0.0, 1.0);
	vec4 color_with_foam = mix(base_water, foam_color, step(0.5, foam_factor));

	ALBEDO = color_with_foam.rgb;
	ROUGHNESS = 0.12;
	METALLIC = 0.05;
	SPECULAR = 0.6;
}
```

---

### 3.2 Shader de Terreno Hexagonal (`game/shaders/hex_ground.gdshader`)

Elimina a cor sólida uniforme dos blocos hexagonais, adicionando variação procedural de tonalidade, oclusão nas frestas e controle de rugosidade.

```glsl
shader_type spatial;

uniform vec3 base_color : source_color = vec3(0.58, 0.72, 0.22);
uniform vec3 edge_color : source_color = vec3(0.38, 0.48, 0.15);
uniform float edge_threshold : hint_range(0.0, 1.0) = 0.15;

uniform float noise_scale = 0.15;
uniform float color_variance : hint_range(0.0, 0.5) = 0.12;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i + vec2(0.0, 0.0)), hash(i + vec2(1.0, 0.0)), u.x),
	           mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

void fragment() {
	// Variação orgânica de tom baseada em coordenadas globais
	vec2 world_pos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xz;
	float n = noise(world_pos * noise_scale);
	vec3 varied_color = base_color + (n - 0.5) * color_variance;

	// Oclusão nas bordas do hexágono (UV centralizada)
	vec2 centered_uv = abs(UV - vec2(0.5)) * 2.0;
	float dist_to_edge = max(centered_uv.x, centered_uv.y);
	float edge_mask = smoothstep(1.0 - edge_threshold, 1.0, dist_to_edge);

	ALBEDO = mix(varied_color, edge_color, edge_mask);
	ROUGHNESS = 0.88;
	SPECULAR = 0.15;
}
```

---

## 4. Sistema de Efeitos Visuais (VFX de Magias e Combate)

### 4.1 Arquitetura de VFX no Godot 4
Cada habilidade instanciará elementos em três camadas integradas:
1. **Mesh / Projétil** com material emissivo (`emission_enabled = true`).
2. **Emissor de Partículas (`GPUParticles3D`)** com curva de transparência (`Alpha Curve`) e cor acelerada.
3. **Luz Dinâmica Efêmera (`OmniLight3D`)** de curta duração (0.15s – 0.3s) que clareia o cenário ao redor do ponto de impacto.

### 4.2 Especificação dos Efeitos por Habilidade

#### Cavaleiro (Tanque — Melee)
* **Ataque Básico (Espada Curta):**
  * *Trail do Golpe:* Malha em arco (*Ribbon/Mesh Trail*) branca translúcida acompanhando a lâmina durante os primeiros 0.25s do golpe.
  * *Impacto:* Emissor de faíscas metálicas alaranjadas (`GPUParticles3D`, 12 partículas, velocidade explosiva `spread = 45°`).
* **Q — Investida:**
  * *Efeito de Arrancada:* Linhas de vento de velocidade cinza-claras atrás dos ombros do Cavaleiro durante o percurso de 6.0 unidades.
  * *Colisão:* Nuvem de poeira semicircular rente ao chão no ponto final do empurrão.
* **E — Muralha:**
  * *Escudo Visual:* Malha curvada frontal usando material translúcido com efeito **Fresnel** (bordas em azul luminoso `Color(0.2, 0.6, 1.0, 0.7)` e centro translúcido com padrão de favo de mel sutil).
* **R — Terremoto (Ultimate):**
  * *Impacto Inicial:* `Decal` projetando rachadura circular de raio 5.0m no chão por 4.0s (com fade out).
  * *Partículas:* Erupção de fragmentos de pedra (`GPUParticles3D`) subindo 2.5m com gravidade e poeira densa.
  * *Onda de Choque:* Anel em expansão horizontal rápida (0.25s) com shader de distorção de refração de tela.

#### Arqueira (Ranger — Ranged)
* **Ataque Básico (Disparo com Arco):**
  * *Projétil:* Flecha com rastro contínuo tênue (`RibbonTrailMesh`, largura 0.08m, vida útil 0.12s) para tornar a trajetória 100% legível na câmera de terceira pessoa.
  * *Impacto:* Faíscas e pequeno flash branco no alvo atingido.
* **Q — Flecha Perfurante:**
  * *Projétil Energizado:* Flecha envolta por espiral de partículas de energia verde-esmeralda/dourada (`emission_energy = 3.5`).
  * *Passagem por Alvos:* Pulso de anel de vento em cada inimigo atravessado, marcando visualmente o decaimento de dano.
* **E — Rolamento:**
  * *Poeira de Esquiva:* 2 tufos rápidos de poeira rente ao solo na direção oposta ao rolamento.
  * *Rastro Fantasma (Ghost Mesh):* Duplicata translúcida do modelo da Arqueira com fade out rápido de 0.2s durante a janela de invulnerabilidade (0.3s).
* **R — Chuva de Flechas (Ultimate):**
  * *Área Indicadora:* Círculo vermelho/âmbar no chão no raio de 4.0m com borda rotativa sutil.
  * *Saraivada:* Projéteis caindo verticalmente do céu em fluxo contínuo durante os 3.0s, intercalando pequenos flashes de impacto no chão.

---

## 5. Enriquecimento da Paisagem (Environment Dressing)

### 5.1 Grama e Vegetação Dinâmica
* **Tufos de Grama 3D:** Em vez de manter o chão liso, posicionar tufos de grama estilizada sobre os hexágonos usando **`MultiMeshInstance3D`** (permite renderizar milhares de tufos com 1 único *Draw Call*).
* **Shader de Vento na Grama:**
  ```glsl
  shader_type spatial;
  uniform vec3 grass_color : source_color = vec3(0.52, 0.75, 0.18);
  uniform float wind_speed = 2.0;
  uniform float wind_strength = 0.15;

  void vertex() {
      // Vento afeta somente o topo da folha de grama (VERTEX.y > 0)
      if (VERTEX.y > 0.1) {
          float wave = sin(TIME * wind_speed + VERTEX.x + VERTEX.z);
          VERTEX.x += wave * wind_strength * VERTEX.y;
      }
  }

  void fragment() {
      ALBEDO = grass_color;
      ROUGHNESS = 0.9;
  }
  ```

### 5.2 Modelagem e Acabamento no Blender
1. **Bevel em Bordas Duras:** No Blender, aplicar o modificador `Bevel` com 1 a 2 segmentos nas quinas vivas dos portões, muralhas e rochas antes de exportar em `.glb`.
2. **Texturas Estilizadas com Curvatura:**
   * Fazer o bake de **Ambient Occlusion** e **Curvature/Pointiness** no Blender.
   * Usar esse mapa como máscara para clarear os chanfros das pedras (simulando desgaste) e escurecer fendas (acumulação de sujeira/sombra).
3. **Margens e Seixos do Rio:**
   * Modelar pequenos seixos e cascalhos baixos ao longo das bordas de contato entre o piso hexagonal e a água para eliminar a quebra seca atual.

---

## 6. Modernização da HUD / Interface (UI/UX)

A HUD atual possui boa diagramação e posicionamento funcional, mas carece de identidade estética de fantasia medieval.

### 6.1 Implementação da "Ghost / Lag Bar" (Feedback de Dano)

A barra de vida deve conter duas camadas de preenchimento sobrepostas: a barra verde imediata e uma barra de amortecimento amarela/vermelha que decresce suavemente com *Tween*.

```gdscript
# health_bar.gd
extends Control

@onready var health_bar_actual: ProgressBar = $ActualHealth
@onready var health_bar_lag: ProgressBar = $LagHealth

var tween: Tween

func update_health(new_hp: float, max_hp: float) -> void:
	health_bar_actual.max_value = max_hp
	health_bar_lag.max_value = max_hp
	
	var old_hp = health_bar_actual.value
	health_bar_actual.value = new_hp
	
	if new_hp < old_hp:
		# Tomou dano: anima a barra fantasma com atraso
		if tween and tween.is_valid():
			tween.kill()
		tween = create_tween()
		tween.tween_interval(0.35) # Espera 350ms antes de descer
		tween.tween_property(health_bar_lag, "value", new_hp, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	else:
		# Cura: atualiza imediatamente
		health_bar_lag.value = new_hp
```

### 6.2 Componentes e Estilo Visual

1. **Molduras Temáticas (`StyleBoxTexture` / `NinePatchRect`):**
   * Substituir os retângulos planos cinza/azul por painéis estilizados com texturas de molduras chanfradas (metal escovado escuro, detalhes dourados nos cantos).
2. **Ícones de Habilidades em Substituição a Textos:**
   * Nos slots `Q`, `E`, `R`, utilizar ilustrações temáticas (ex: espada em investida, escudo de energia, rachadura sísmica).
   * A tecla de atalho (`Q`, `E`, `R`) deve ficar como uma pequena *badge* metálica quadrada posicionada no canto inferior direito do slot.
3. **Tipografia:**
   * Substituir a fonte padrão por uma tipografia de fantasia/ação com boa legibilidade (ex: *Cinzel*, *Barlow Condensed* ou *Montserrat Semi-Bold*).
   * Habilitar contorno escuro nas fontes (`Font Outline = 1px a 2px`, cor `#000000`) para garantir 100% de contraste sobre fundos claros ou escuros da arena.
4. **Iluminação de 3 Pontos na Tela de Seleção de Campeão:**
   * Na cena de seleção, configurar iluminação de estúdio no modelo 3D:
     * **Key Light:** Luz frontal/superior quente.
     * **Fill Light:** Luz lateral fria suave para diminuir sombras duras.
     * **Rim Light (Traseira):** Luz intensa azulada ou dourada posicionada atrás do herói para delinear o contorno da armadura contra o fundo escuro.

---

## 7. Cronograma e Fases de Execução Técnica

A ordem recomendada de implementação prioriza as ações que exigem menor esforço e entregam o maior impacto visual perceptível:

| Fase | Foco | Tarefas Técnicas | Arquivos Impactados |
|:---:|---|---|---|
| **Fase 1** | **Iluminação & Atmosfera** | Configurar `WorldEnvironment` (ACES, SSAO, Glow, Neblina) e luz solar com sombras suaves. | `game/scenes/arena/arena.tscn` |
| **Fase 2** | **Shaders de Água e Chão** | Criar e vincular `water.gdshader` e `hex_ground.gdshader` aos materiais existentes. | `game/shaders/`, `game/data/materials/` |
| **Fase 3** | **VFX de Combate** | Criar cenas de impacto de golpes melee, trilha de flechas (`RibbonTrailMesh`) e poeiras de investida. | `game/scenes/vfx/` |
| **Fase 4** | **Polimento de UI** | Integrar `LagHealthBar` na HUD e adicionar ícones estilizados com badges de atalho. | `game/scenes/ui/hud.tscn` |
| **Fase 5** | **Vegetação & Blender** | Espalhar tufos de grama via `MultiMeshInstance3D` e suavizar quinas dos modelos 3D no Blender. | `game/scenes/arena/props/`, `.blend` |
