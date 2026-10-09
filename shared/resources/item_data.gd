class_name ItemData
extends Resource
## Equipamento de um dos 4 slots (GDB §6.1). Bonus planos somam ao atributo;
## agility_pct multiplica a AGI (0.10 = +10 %).

enum Slot { WEAPON, HELM, CHEST, BOOTS }
enum Rarity { COMMON, RARE, EPIC }

@export var id: StringName
@export var display_name: String
@export var slot: Slot
@export var rarity: Rarity
## Conjunto a que pertence (&"guard", &"hunter"); vazio = sem conjunto.
@export var set_id: StringName
@export var hp: float
@export var defense: float
@export var attack: float
@export var intelligence: float
@export var agility: float
@export var agility_pct: float
## Passiva unica (&"fury"); vazio = nenhuma. O efeito e aplicado pelo combate.
@export var passive: StringName
@export var passive_value: float
