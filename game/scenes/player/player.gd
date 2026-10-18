# Author: Karl Bien Madrid
class_name Player
extends CharacterBody2D
## The playable creature. Moves in 8 directions; stats come from `character`.

const BODY_RADIUS := 16.0

@export var character: CharacterData

var facing := Vector2.RIGHT


func _physics_process(_delta: float) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input * character.move_speed
	if input != Vector2.ZERO:
		facing = input.normalized()
		queue_redraw()
	move_and_slide()


func _draw() -> void:
	# Placeholder art: a colored circle with a line showing which way it faces.
	draw_circle(Vector2.ZERO, BODY_RADIUS, character.placeholder_color)
	draw_line(Vector2.ZERO, facing * (BODY_RADIUS + 6.0), Color.WHITE, 3.0)
