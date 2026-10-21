# Author: Karl Bien Madrid
class_name MetaUpgradeData
extends Resource
## A permanent upgrade sold at Bathala's shrine for Diwa. Kept between runs.
## Each level adds `amount_per_level`; `costs` holds the price of each level.

@export var display_name: String = ""
@export_multiline var description: String = ""
@export_enum("max_health", "attack_damage", "move_speed", "room_clear_heal", "diwa_chance", "second_life") var effect: String = "max_health"
@export var amount_per_level: float = 0.0
## Diwa price of level 1, 2, 3... The number of prices is the max level.
@export var costs: Array[int] = []


func max_level() -> int:
	return costs.size()
