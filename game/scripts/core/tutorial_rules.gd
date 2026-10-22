class_name TutorialRules
extends RefCounted
## Tutorial guiado (F85, SPEC-085 §2): os 6 passos como regra pura. Cada passo avanca quando o
## jogador faz a acao (Progress); o roteiro so ordena eventos e mostra instrucoes, nao muda numeros.
## Quem observa o jogo e preenche o Progress e o TutorialDirector; os textos moram aqui para a UI
## so exibir.

enum Step {
	MOVE_CAMERA,
	TARGET_ATTACK,
	SKILLS,
	MONSTER_XP,
	CHEST_SHEET,
	PHASE2,
	DONE,
}

## Passos que o jogador percorre (DONE e o estado final).
const STEP_COUNT: int = Step.DONE
## Heroi fixo do tutorial (SPEC-085 §2).
const HERO_ID: StringName = &"knight"
## Nivel dos herois no inicio: o R do Cavaleiro exige o nivel 6, e o passo 3 vem antes de qualquer
## XP; os ranks tipicos desse nivel ja trazem Q, E e R aprendidos.
const START_LEVEL: int = 6
## Nivel 1 de bot_levels.tres (ADR-0027): o bot Facil do passo 6.
const BOT_LEVEL: int = 1
## Passo 1: distancia andada (u) e giro acumulado da camera (rad) que contam como "fez".
const MOVE_DISTANCE: float = 6.0
const ORBIT_RADIANS: float = 0.35
## Passo 4: o abate tem de fechar o nivel; falta este tanto de XP para o proximo nivel.
const XP_LEFT_BEFORE_LEVEL_UP: int = 1

const TEXT_MOVE_CAMERA: String = (
	"Ande com %s. Segure o %s e arraste para girar a câmera. "
	+ "Use a roda do mouse (ou %s e %s) para o zoom."
)
const TEXT_TARGET_ATTACK: String = (
	"Clique com o %s no monstro marcado para travar o alvo. "
	+ "O herói ataca sozinho quando ele está ao alcance; chegue perto."
)
const TEXT_SKILLS: String = (
	"Use as três habilidades contra o monstro: %s, %s e %s. " + "Cada uma tem recarga."
)
const TEXT_MONSTER_XP: String = (
	"Derrote o monstro para ganhar XP e subir de nível. "
	+ "Depois gaste o ponto de habilidade com Ctrl + %s, %s ou %s."
)
const TEXT_CHEST_SHEET: String = (
	"Chegue ao baú marcado e aperte %s. Clique em um dos itens para levá-lo. "
	+ "Depois abra a ficha do herói com %s."
)
const TEXT_PHASE2: String = (
	"A zona está fechando e um bot entrou na arena. " + "Vença o bot para concluir o tutorial."
)
const TEXT_DONE: String = "Pronto! Você já sabe jogar."

const KEY_ORBIT: String = "botão esquerdo do mouse"
const KEY_ATTACK: String = "botão direito do mouse"


## O que o jogador ja fez, preenchido pelo TutorialDirector. Cada campo vale para o passo do
## comentario.
class Progress:
	extends RefCounted
	## 1: distancia andada (u), giro acumulado da camera (rad) e zoom.
	var moved: float = 0.0
	var orbited: float = 0.0
	var zoomed: bool = false
	## 2: alvo travado e golpe acertado.
	var targeted: bool = false
	var struck: bool = false
	## 3: Q, E e R usados.
	var used_q: bool = false
	var used_e: bool = false
	var used_r: bool = false
	## 4: monstro abatido, nivel subiu e o ponto foi gasto.
	var monster_killed: bool = false
	var leveled: bool = false
	var point_spent: bool = false
	## 5: bau aberto, item levado e ficha (B) aberta.
	var chest_opened: bool = false
	var item_taken: bool = false
	var sheet_opened: bool = false
	## 6: o jogador venceu a partida contra o bot.
	var won: bool = false


static func is_complete(step: Step, progress: Progress) -> bool:
	match step:
		Step.MOVE_CAMERA:
			return (
				progress.moved >= MOVE_DISTANCE
				and progress.orbited >= ORBIT_RADIANS
				and progress.zoomed
			)
		Step.TARGET_ATTACK:
			return progress.targeted and progress.struck
		Step.SKILLS:
			return progress.used_q and progress.used_e and progress.used_r
		Step.MONSTER_XP:
			return progress.monster_killed and progress.leveled and progress.point_spent
		Step.CHEST_SHEET:
			return progress.chest_opened and progress.item_taken and progress.sheet_opened
		Step.PHASE2:
			return progress.won
	return false


static func next(step: Step) -> Step:
	return (mini(step + 1, Step.DONE)) as Step


## XP a somar para o heroi ficar a [constant XP_LEFT_BEFORE_LEVEL_UP] do proximo nivel (o proximo
## abate o fecha). 0 se ja esta mais perto que isso ou no nivel maximo.
static func xp_top_up(curve: XpCurve, xp: int) -> int:
	var level := XpTable.level_for_xp(curve, xp)
	if level >= XpTable.max_level(curve):
		return 0
	var target := XpTable.xp_for_level(curve, level + 1) - XP_LEFT_BEFORE_LEVEL_UP
	return maxi(target - xp, 0)


static func title(step: Step) -> String:
	var titles: Dictionary[Step, String] = {
		Step.MOVE_CAMERA: "Mover e câmera",
		Step.TARGET_ATTACK: "Alvo e ataque",
		Step.SKILLS: "Habilidades",
		Step.MONSTER_XP: "Monstro e XP",
		Step.CHEST_SHEET: "Baú e ficha",
		Step.PHASE2: "Fase 2",
	}
	return TranslationServer.translate(titles.get(step, "Tutorial concluído"))


## Instrucao do passo com as teclas de verdade (remapeadas no Launcher, F24).
static func instruction(step: Step) -> String:
	match step:
		Step.MOVE_CAMERA:
			var walk: String = (
				InputActions.key_label(InputActions.MOVE_FORWARD)
				+ InputActions.key_label(InputActions.MOVE_LEFT)
				+ InputActions.key_label(InputActions.MOVE_BACK)
				+ InputActions.key_label(InputActions.MOVE_RIGHT)
			)
			return _say(
				TEXT_MOVE_CAMERA,
				[
					walk,
					TranslationServer.translate(KEY_ORBIT),
					InputActions.key_label(InputActions.CAMERA_ZOOM_IN),
					InputActions.key_label(InputActions.CAMERA_ZOOM_OUT),
				]
			)
		Step.TARGET_ATTACK:
			return _say(TEXT_TARGET_ATTACK, [TranslationServer.translate(KEY_ATTACK)])
		Step.SKILLS:
			return _say(TEXT_SKILLS, InputActions.skill_labels())
		Step.MONSTER_XP:
			return _say(TEXT_MONSTER_XP, InputActions.skill_labels())
		Step.CHEST_SHEET:
			return _say(
				TEXT_CHEST_SHEET,
				[
					InputActions.key_label(InputActions.INTERACT),
					InputActions.key_label(InputActions.OPEN_BESTIARY),
				]
			)
		Step.PHASE2:
			return TranslationServer.translate(TEXT_PHASE2)
	return TranslationServer.translate(TEXT_DONE)


static func _say(text: String, args: Array) -> String:
	return TranslationServer.translate(text) % args
