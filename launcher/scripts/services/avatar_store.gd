class_name AvatarStore
extends RefCounted
## Avatar de cada conta (F35, R-PEND-02): imagem predefinida (retrato de heroi ou monstro dos
## assets reais) ou upload ja recortado em 256x256. Fica SO local, em user://: nao vai ao backend
## nem aparece para outros jogadores. A escolha e por id de conta (varias contas na mesma maquina).
## Predefinido = "hero:<id>" ou "monster:<id>"; upload = UPLOAD, com o PNG em <dir>/<conta>.png.

const DIR: String = "user://avatars/"
const CHOICES_FILE: String = "choices.cfg"
const SECTION: String = "avatar"
const UPLOAD: String = "upload"
const TEMP_SUFFIX: String = ".tmp"
const HERO_PREFIX: String = "hero:"
const MONSTER_PREFIX: String = "monster:"
const MONSTER_PORTRAITS_DIR: String = "res://shared/assets/ui/monsters/"
const MONSTERS_DIR: String = "res://shared/data/monsters/"
## UUID da conta vira nome de arquivo: so isso entra (\z: o "$" do PCRE aceitaria um "\n").
const USER_ID_PATTERN: String = "^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\\z"
const ID_PATTERN: String = "^[a-z0-9_]+\\z"

static var _user_regex: RegEx = RegEx.create_from_string(USER_ID_PATTERN)
static var _id_regex: RegEx = RegEx.create_from_string(ID_PATTERN)

var _dir: String


func _init(dir: String = DIR) -> void:
	_dir = dir


## Ids dos avatares predefinidos: herois e monstros que tem retrato, na ordem do catalogo.
static func presets(catalog: CatalogService) -> Array[String]:
	var ids: Array[String] = []
	for hero: HeroData in catalog.heroes:
		if HistoryFormat.portrait(hero.id) != null:
			ids.append(HERO_PREFIX + hero.id)
	for monster: MonsterData in catalog.monsters:
		var id := MONSTER_PREFIX + monster.id
		if preset_texture(id) != null:
			ids.append(id)
	return ids


## Retrato do predefinido; null se o id nao for de um (fora do padrao ou sem arquivo).
static func preset_texture(preset: String) -> Texture2D:
	if preset.begins_with(HERO_PREFIX):
		return HistoryFormat.portrait(preset.trim_prefix(HERO_PREFIX))
	if preset.begins_with(MONSTER_PREFIX):
		var id := preset.trim_prefix(MONSTER_PREFIX)
		if _id_regex.search(id) == null:
			return null
		var path := "%s%s.png" % [MONSTER_PORTRAITS_DIR, id]
		return load(path) as Texture2D if ResourceLoader.exists(path) else null
	return null


## Nome de exibicao do predefinido ("Cavaleiro da Aurora"); "" se nao existir.
static func preset_name(preset: String) -> String:
	if preset_texture(preset) == null:
		return ""
	if preset.begins_with(HERO_PREFIX):
		return HistoryFormat.hero_name(preset.trim_prefix(HERO_PREFIX))
	var path := "%s%s.tres" % [MONSTERS_DIR, preset.trim_prefix(MONSTER_PREFIX)]
	var data := load(path) as MonsterData if ResourceLoader.exists(path) else null
	return data.display_name if data != null else ""


## Escolha da conta: "", "upload" ou o id do predefinido.
func choice(user_id: String) -> String:
	if _user_regex.search(user_id) == null:
		return ""
	var cfg := _load()
	return str(cfg.get_value(SECTION, user_id, ""))


func use_preset(user_id: String, preset: String) -> bool:
	if _user_regex.search(user_id) == null or preset_texture(preset) == null:
		return false
	return _remember(user_id, preset)


## Grava o PNG 256x256 da conta e passa a usa-lo. Outro tamanho e recusado (o AvatarImage ja
## entrega 256x256).
func save_upload(user_id: String, image: Image) -> bool:
	if _user_regex.search(user_id) == null or image == null:
		return false
	if image.get_size() != Vector2i(AvatarImage.SIZE, AvatarImage.SIZE):
		return false
	if DirAccess.make_dir_recursive_absolute(_dir) != OK:
		return false
	# Grava ao lado e renomeia: falha no meio nao deixa a escolha apontando para arquivo quebrado.
	var path := _upload_path(user_id)
	var partial := path + TEMP_SUFFIX
	if image.save_png(partial) != OK:
		return false
	if DirAccess.rename_absolute(partial, path) != OK:
		DirAccess.remove_absolute(partial)
		return false
	return _remember(user_id, UPLOAD)


## Textura do avatar da conta; null sem escolha (a tela mostra o icone padrao) ou arquivo sumido.
func texture(user_id: String) -> Texture2D:
	var current := choice(user_id)
	if current != UPLOAD:
		return preset_texture(current)
	var path := _upload_path(user_id)
	if not FileAccess.file_exists(path):
		return null
	var image := Image.load_from_file(path)
	if image == null or image.is_empty():
		return null
	return ImageTexture.create_from_image(image)


func _upload_path(user_id: String) -> String:
	return "%s%s.png" % [_dir, user_id]


func _load() -> ConfigFile:
	var cfg := ConfigFile.new()
	cfg.load(_dir + CHOICES_FILE)  # sem arquivo = ninguem escolheu ainda
	return cfg


func _remember(user_id: String, value: String) -> bool:
	if DirAccess.make_dir_recursive_absolute(_dir) != OK:
		return false
	var cfg := _load()
	cfg.set_value(SECTION, user_id, value)
	return cfg.save(_dir + CHOICES_FILE) == OK
