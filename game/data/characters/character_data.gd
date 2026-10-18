# Author: Karl Bien Madrid
class_name CharacterData
extends Resource
## Stats and info for one playable folklore creature.
## Make a new .tres file from this to add a character - no new code needed.

@export var display_name: String = ""
@export_multiline var description: String = ""
@export var max_health: int = 100
@export var move_speed: float = 220.0
## Placeholder body color until the real sprite is ready.
@export var placeholder_color: Color = Color.WHITE
