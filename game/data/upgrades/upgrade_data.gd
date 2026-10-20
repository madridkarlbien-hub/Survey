# Author: Karl Bien Madrid
class_name UpgradeData
extends Resource
## One level-up choice: adds `amount` to one of the character's stats.
## Use a negative amount to lower a stat (e.g. a shorter attack cooldown).

@export var display_name: String = ""
@export_multiline var description: String = ""
@export_enum("max_health", "move_speed", "pickup_radius", "attack_damage", "attack_radius", "attack_cooldown", "attack_knockback") var stat: String = "attack_damage"
@export var amount: float = 0.0
