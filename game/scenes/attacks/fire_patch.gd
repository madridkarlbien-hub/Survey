# Author: Karl Bien Madrid
class_name FirePatch
extends Node2D
## A patch of fire left by Blazing Trail. Burns enemies standing in it, then fades.

const RADIUS := 28.0

var damage_per_second := 6.0
var lifetime := 2.0

var _age := 0.0


func _physics_process(delta: float) -> void:
	_age += delta
	if _age >= lifetime:
		queue_free()
		return
	for enemy: Enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.global_position.distance_to(global_position) <= RADIUS + enemy.data.radius:
			enemy.hurt(damage_per_second * delta, false)
	queue_redraw()


func _draw() -> void:
	# Placeholder effect: an orange glow that fades out.
	var fade := 1.0 - _age / lifetime
	draw_circle(Vector2.ZERO, RADIUS, Color(1.0, 0.45, 0.1, 0.35 * fade))
	draw_circle(Vector2.ZERO, RADIUS * 0.5, Color(1.0, 0.75, 0.2, 0.5 * fade))
