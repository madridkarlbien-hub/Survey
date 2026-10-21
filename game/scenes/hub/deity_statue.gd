# Author: Karl Bien Madrid
class_name DeityStatue
extends StaticBody2D
## A deity standing in the realm of the gods. Solid, so the player walks around it.
## Placeholder art: a glowing circle in the deity's color, with its name below.

const RADIUS := 28.0

@export var deity: DeityData


func _ready() -> void:
	var shape := CircleShape2D.new()
	shape.radius = RADIUS
	var collision := CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)
	$Name.text = deity.display_name
	$Name.modulate = deity.color
	$Domain.text = deity.domain


func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS + 10.0, Color(deity.color, 0.15))
	draw_circle(Vector2.ZERO, RADIUS, deity.color.darkened(0.35))
	draw_arc(Vector2.ZERO, RADIUS, 0.0, TAU, 32, deity.color, 3.0)
