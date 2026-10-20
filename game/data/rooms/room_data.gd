# Author: Karl Bien Madrid
class_name RoomData
extends Resource
## One kind of combat room: its size, its waves, and how it is cleared.

enum ClearMode {
	DEFEAT_ALL, ## Every wave plays once; defeat every enemy to clear.
	SURVIVE, ## The last wave keeps repeating; survive `survive_time` to clear.
}

@export var display_name: String = ""
@export var clear_mode: ClearMode = ClearMode.DEFEAT_ALL
## Seconds to survive (SURVIVE rooms only).
@export var survive_time: float = 45.0
@export var room_size: Vector2 = Vector2(2400, 1600)
@export var wave_set: WaveSet
## If on, deeper rooms in the run spawn more enemies. Off for the boss room.
@export var scales_with_depth: bool = true
