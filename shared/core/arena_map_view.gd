class_name ArenaMapView
extends RefCounted
## Enquadramento do render estatico da arena (shared/assets/ui/arena_map.png, F33): camera
## ortografica ao sul olhando o centro, inclinada, norte para cima. A ferramenta de render
## (tools/ui/render_arena_map.gd) e a tela Arena & Mapa usam estas mesmas constantes: a tela
## coloca cada marcador no pixel certo por aqui. Mudou o enquadramento, regere a imagem.

## Inclinacao da camera sobre o plano do chao (graus).
const PITCH_DEGREES: float = 45.0
## Altura do quadro no plano da camera (Camera3D.size com keep_aspect = KEEP_HEIGHT), em unidades.
const VIEW_HEIGHT: float = 72.0
## Proporcao do quadro: o card do mapa do prototipo e 16:9.
const ASPECT: float = 16.0 / 9.0
## Distancia da camera ao centro (so precisa passar acima do relevo mais alto).
const CAMERA_DISTANCE: float = 220.0
## Centro da imagem em (u, v).
const MIDDLE: float = 0.5


## Posicao no chao (x, z do mundo) mais altura [param height] -> (u, v) em [0, 1] da imagem.
static func world_to_uv(ground: Vector2, height: float = 0.0) -> Vector2:
	var pitch := deg_to_rad(PITCH_DEGREES)
	var screen_up := height * cos(pitch) - ground.y * sin(pitch)
	return Vector2(
		MIDDLE + ground.x / (VIEW_HEIGHT * ASPECT),
		MIDDLE - screen_up / VIEW_HEIGHT,
	)


## Inverso de world_to_uv para um ponto no chao (altura 0).
static func uv_to_world(uv: Vector2) -> Vector2:
	var pitch := deg_to_rad(PITCH_DEGREES)
	return Vector2(
		(uv.x - MIDDLE) * VIEW_HEIGHT * ASPECT,
		(uv.y - MIDDLE) * VIEW_HEIGHT / sin(pitch),
	)


## Pose da camera de render: ao sul do centro, olhando para o norte e para baixo.
static func camera_transform() -> Transform3D:
	var pitch := deg_to_rad(PITCH_DEGREES)
	var origin := Vector3(0.0, sin(pitch), cos(pitch)) * CAMERA_DISTANCE
	return Transform3D(Basis(Vector3.RIGHT, -pitch), origin)
