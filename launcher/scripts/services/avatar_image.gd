class_name AvatarImage
extends RefCounted
## Upload de avatar (F35, R-PEND-02): PNG ou JPG de ate 1 MB, recortado no quadrado central e
## redimensionado para 256x256. O formato vem dos bytes (assinatura), nao da extensao do arquivo.
## O arquivo e do proprio jogador e fica so no disco local; nada aqui vai ao backend.

const SIZE: int = 256
## 1 MB = 1 MiB (limite do arquivo escolhido, antes de decodificar).
const MAX_BYTES: int = 1048576
## Teto de largura e altura lidas do cabecalho ANTES de decodificar: 1 MB de PNG/JPG pode declarar
## dezenas de milhares de pixels por lado (bomba de descompressao) e estourar a memoria.
const MAX_SIDE: int = 4096
const TOO_LARGE: String = "AVATAR_TOO_LARGE"
const TOO_BIG: String = "AVATAR_TOO_BIG_DIMENSIONS"
const BAD_FORMAT: String = "AVATAR_BAD_FORMAT"
const PNG_SIGNATURE: PackedByteArray = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
const JPG_SIGNATURE: PackedByteArray = [0xFF, 0xD8, 0xFF]
## PNG: largura e altura (4 bytes cada) logo depois da assinatura e do cabecalho do IHDR.
const PNG_WIDTH_AT: int = 16
const PNG_IHDR_END: int = 24
## JPG: marcadores SOF0-SOF15 (menos DHT, JPG e DAC) trazem largura e altura a +7 e +5 do 0xFF.
const JPG_SOF_MARKERS: Array[int] = [
	0xC0, 0xC1, 0xC2, 0xC3, 0xC5, 0xC6, 0xC7, 0xC9, 0xCA, 0xCB, 0xCD, 0xCE, 0xCF
]
const JPG_SEGMENT_HEAD: int = 4
const JPG_SOF_HEIGHT: int = 5
const JPG_SOF_WIDTH: int = 7
const JPG_SOF_END: int = 9
const MESSAGES: Dictionary[String, String] = {
	TOO_LARGE: "A imagem passa de 1 MB. Escolha um arquivo menor.",
	TOO_BIG: "A imagem tem dimensões grandes demais (máximo 4096 × 4096 pixels).",
	BAD_FORMAT: "Arquivo inválido. Use uma imagem PNG ou JPG.",
}


## Resultado: a imagem 256x256 pronta, ou o codigo do erro.
class Result:
	extends RefCounted
	var ok: bool = false
	var image: Image = null
	var code: String = ""


static func prepare(bytes: PackedByteArray) -> Result:
	var result := Result.new()
	if bytes.size() > MAX_BYTES:
		result.code = TOO_LARGE
		return result
	var size := _declared_size(bytes)
	if size.x > MAX_SIDE or size.y > MAX_SIDE:
		result.code = TOO_BIG
		return result
	var image := _decode(bytes)
	if image == null or image.is_empty():
		result.code = BAD_FORMAT
		return result
	var side := mini(image.get_width(), image.get_height())
	var crop := Rect2i((image.get_width() - side) / 2, (image.get_height() - side) / 2, side, side)
	var square := image.get_region(crop)
	square.convert(Image.FORMAT_RGBA8)
	square.resize(SIZE, SIZE, Image.INTERPOLATE_LANCZOS)
	result.image = square
	result.ok = true
	return result


## Le o arquivo escolhido pelo jogador. Acima de 1 MB nem e lido (o tamanho vem do disco).
static func prepare_file(path: String) -> Result:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		var result := Result.new()
		result.code = BAD_FORMAT
		return result
	if file.get_length() > MAX_BYTES:
		var result := Result.new()
		result.code = TOO_LARGE
		return result
	return prepare(file.get_buffer(file.get_length()))


static func message(code: String) -> String:
	return TranslationServer.translate(MESSAGES.get(code, MESSAGES[BAD_FORMAT]))


## Largura e altura declaradas no cabecalho (PNG: IHDR; JPG: primeiro SOFn); (0, 0) se nao achar:
## o decoder decide o que fazer com o arquivo.
static func _declared_size(bytes: PackedByteArray) -> Vector2i:
	if bytes.slice(0, PNG_SIGNATURE.size()) == PNG_SIGNATURE:
		if bytes.size() < PNG_IHDR_END:
			return Vector2i.ZERO
		return Vector2i(_be32(bytes, PNG_WIDTH_AT), _be32(bytes, PNG_WIDTH_AT + 4))
	if bytes.slice(0, JPG_SIGNATURE.size()) != JPG_SIGNATURE:
		return Vector2i.ZERO
	var at := 2
	while at + JPG_SEGMENT_HEAD <= bytes.size():
		if bytes[at] != 0xFF:
			return Vector2i.ZERO
		var marker := bytes[at + 1]
		if marker == 0xFF:
			at += 1  # preenchimento
			continue
		if marker in JPG_SOF_MARKERS:
			if at + JPG_SOF_END > bytes.size():
				return Vector2i.ZERO
			return Vector2i(_be16(bytes, at + JPG_SOF_WIDTH), _be16(bytes, at + JPG_SOF_HEIGHT))
		at += 2 + _be16(bytes, at + 2)  # pula o segmento (marcador + tamanho + dados)
	return Vector2i.ZERO


static func _be16(bytes: PackedByteArray, at: int) -> int:
	return (bytes[at] << 8) | bytes[at + 1]


static func _be32(bytes: PackedByteArray, at: int) -> int:
	return (_be16(bytes, at) << 16) | _be16(bytes, at + 2)


## null = nao e PNG/JPG ou o conteudo esta quebrado.
static func _decode(bytes: PackedByteArray) -> Image:
	var image := Image.new()
	if bytes.slice(0, PNG_SIGNATURE.size()) == PNG_SIGNATURE:
		return image if image.load_png_from_buffer(bytes) == OK else null
	if bytes.slice(0, JPG_SIGNATURE.size()) == JPG_SIGNATURE:
		return image if image.load_jpg_from_buffer(bytes) == OK else null
	return null
