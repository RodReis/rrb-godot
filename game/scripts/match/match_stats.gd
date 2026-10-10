class_name MatchStats
extends RefCounted
## Estatisticas da partida 1x1 para a tela de fim (F18, DV tela 7). O servidor (MatchController)
## soma durante a partida o que so existe como evento (mortes, monstros, baus, Rei Esqueleto) e,
## no fim, copia do estado o resto (heroi, nivel, kills da fase 2, dano, equipamento) e a
## duracao pelo relogio. Vai aos clientes no match_ended como Dictionary (to_dict / from_dict);
## a UI so exibe. Kills sao as da fase 2, as unicas que contam (GDB §3.3).

## Jogadores aceitos vindos da rede (1x1).
const MAX_PLAYERS: int = 2
## Campos de Player que viajam na rede, com o tipo checado na chegada.
const FIELDS: Array[String] = [
	"peer",
	"hero",
	"kills",
	"deaths",
	"level",
	"hero_damage",
	"damage_taken",
	"monsters",
	"chests",
	"boss_killed",
	"equipment",
]


## Um jogador.
class Player:
	extends RefCounted
	var peer: int = 0
	## Numero de Ids do heroi (Ids.NONE sem heroi).
	var hero: int = Ids.NONE
	var kills: int = 0
	var deaths: int = 0
	var level: int = 0
	var hero_damage: int = 0
	var damage_taken: int = 0
	## Monstros abatidos (golpe final), sem o Rei Esqueleto, que tem linha propria.
	var monsters: int = 0
	var chests: int = 0
	var boss_killed: bool = false
	## Numero de Ids por ItemData.Slot (Inventory).
	var equipment: Vector4i = Inventory.NONE


## Segundos de partida no fim (relogio desde o inicio da fase 1).
var duration: float = 0.0

var _players: Dictionary[int, Player] = {}


## O jogador [param peer], criado na primeira vez.
func player(peer: int) -> Player:
	if not _players.has(peer):
		var created := Player.new()
		created.peer = peer
		_players[peer] = created
	return _players[peer]


func has(peer: int) -> bool:
	return _players.has(peer)


func players() -> Array[Player]:
	var result: Array[Player] = []
	for one: Player in _players.values():
		result.append(one)
	return result


## O outro jogador do 1x1; null se nao ha.
func opponent_of(peer: int) -> Player:
	for other: Player in _players.values():
		if other.peer != peer:
			return other
	return null


func to_dict() -> Dictionary:
	var entries: Array[Dictionary] = []
	for one: Player in _players.values():
		var entry := {}
		for field: String in FIELDS:
			entry[field] = one.get(field)
		entries.append(entry)
	return {"duration": duration, "players": entries}


## Vindo da rede: campo desconhecido ou de tipo errado fica no padrao; entrada sem peer e
## ignorada; no maximo um jogador por vaga.
static func from_dict(data: Dictionary) -> MatchStats:
	var stats := MatchStats.new()
	var seconds: Variant = data.get("duration", 0.0)
	if seconds is float:
		stats.duration = seconds
	var entries: Variant = data.get("players", [])
	if not entries is Array:
		return stats
	for entry: Variant in entries:
		if stats.players().size() >= MAX_PLAYERS:
			break
		if not entry is Dictionary or not (entry as Dictionary).get("peer") is int:
			continue
		var row: Dictionary = entry
		var one := stats.player(row["peer"])
		for field: String in FIELDS:
			var value: Variant = row.get(field)
			if typeof(value) == typeof(one.get(field)):
				one.set(field, value)
	return stats
