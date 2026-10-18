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
