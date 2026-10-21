# Author: Karl Bien Madrid
class_name EnemyData
extends Resource
## Stats for one enemy type.
## Make a new .tres file from this to add an enemy - no new code needed.

@export var display_name: String = ""
@export var max_health: int = 10
@export var move_speed: float = 110.0
@export var contact_damage: int = 5
@export var radius: float = 12.0
## Placeholder body color until the real sprite is ready.
@export var placeholder_color: Color = Color.WHITE
## XP dropped when defeated.
@export var xp_value: int = 1
## 0 = full knockback, 1 = can't be pushed at all.
@export_range(0.0, 1.0) var knockback_resistance: float = 0.0
## Draw a health bar above this enemy (for bosses).
@export var show_health_bar: bool = false
## Chance (0-1) to also drop Diwa when defeated.
@export_range(0.0, 1.0) var diwa_chance: float = 0.08
@export var diwa_amount: int = 1
