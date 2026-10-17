extends GutTest
## Inventario de licencas (SPEC-073 aceite): todo arquivo de `shared/assets/textures/<area>/` tem
## a pasta e o conjunto (`<conjunto>_*`) listados numa linha de `shared/assets/LICENSES.md`.

const TEXTURES_DIR: String = "res://shared/assets/textures"
const LICENSES: String = "res://shared/assets/LICENSES.md"
const EXTENSIONS: PackedStringArray = ["jpg", "jpeg", "png", "webp", "exr"]
const MAPS: PackedStringArray = ["albedo", "normal", "rough"]
const MAX_SIZE: int = 2048


func test_every_texture_set_is_listed_in_licenses() -> void:
	var rows := FileAccess.get_file_as_string(LICENSES).split("\n")
	var sets := _texture_sets()
	assert_gt(sets.size(), 0, "nenhuma textura em %s" % TEXTURES_DIR)
	for entry: String in sets:
		var parts := entry.split("/")
		assert_true(
			_has_row(rows, "textures/%s/" % parts[0], "%s_" % parts[1]),
			"LICENSES.md sem linha para textures/%s/ com %s_*" % [parts[0], parts[1]],
		)


func test_every_texture_set_has_all_maps() -> void:
	for entry: String in _texture_sets():
		var parts := entry.split("/")
		for map: String in MAPS:
			var found := false
			for ext: String in EXTENSIONS:
				if FileAccess.file_exists(
					"%s/%s/%s_%s.%s" % [TEXTURES_DIR, parts[0], parts[1], map, ext]
				):
					found = true
			assert_true(found, "conjunto %s sem mapa %s" % [entry, map])


func test_textures_are_at_most_2k() -> void:
	for area: String in DirAccess.get_directories_at(TEXTURES_DIR):
		for file: String in DirAccess.get_files_at("%s/%s" % [TEXTURES_DIR, area]):
			if file.get_extension() not in EXTENSIONS:
				continue
			var texture := load("%s/%s/%s" % [TEXTURES_DIR, area, file]) as Texture2D
			assert_not_null(texture, file)
			if texture != null:
				assert_lte(maxi(texture.get_width(), texture.get_height()), MAX_SIZE, file)


## "<area>/<conjunto>" de cada arquivo de textura (conjunto = nome sem o sufixo do mapa).
func _texture_sets() -> PackedStringArray:
	var result := PackedStringArray()
	for area: String in DirAccess.get_directories_at(TEXTURES_DIR):
		for file: String in DirAccess.get_files_at("%s/%s" % [TEXTURES_DIR, area]):
			if file.get_extension() not in EXTENSIONS:
				continue
			var stem := file.get_basename()
			var entry := "%s/%s" % [area, stem.substr(0, stem.rfind("_"))]
			if entry not in result:
				result.append(entry)
	return result


func _has_row(rows: PackedStringArray, folder: String, set_prefix: String) -> bool:
	for row: String in rows:
		if row.begins_with("|") and row.contains(folder) and row.contains(set_prefix):
			return true
	return false
