# Author: Karl Bien Madrid
class_name XpOrb
extends Node2D
## Dropped by defeated enemies. Flies to the player once they are close enough.

const FLY_SPEED := 500.0
const COLLECT_DISTANCE := 18.0

var value := 1

var _flying := false
var _player: Player


func _ready() -> void:
	_player = get_tree().get_first_node_in_group("player")


## Fly to the player from anywhere (used when a room is cleared).
func attract() -> void:
	_flying = true


func _physics_process(delta: float) -> void:
	if _player == null or _player.health <= 0:
		return
	if global_position.distance_to(_player.global_position) <= _player.character.pickup_radius:
		_flying = true
	if not _flying:
		return
	global_position = global_position.move_toward(_player.global_position, FLY_SPEED * delta)
	if global_position.distance_to(_player.global_position) <= COLLECT_DISTANCE:
		_player.add_xp(value)
		queue_free()


func _draw() -> void:
	# Placeholder art: a small glowing cyan gem.
	draw_circle(Vector2.ZERO, 6.0, Color(0.3, 0.9, 1.0, 0.35))
	draw_circle(Vector2.ZERO, 4.0, Color(0.5, 0.95, 1.0))
