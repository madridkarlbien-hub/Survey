# Author: Karl Bien Madrid
class_name Shockwave
extends Node2D
## The Tikbalang's stomp. Every few seconds, a ring of force hurts and pushes
## back all enemies within range. Must be a child of the Player.

const FIRST_PULSE_DELAY := 1.0
const RING_TIME := 0.25

var _player: Player
var _cooldown_left := FIRST_PULSE_DELAY
var _ring_time_left := 0.0


func _ready() -> void:
	_player = get_parent()


func _physics_process(delta: float) -> void:
	if _player.health <= 0:
		return
	_cooldown_left -= delta
	if _cooldown_left <= 0.0:
		_cooldown_left += _player.character.attack_cooldown
		_pulse()
	if _ring_time_left > 0.0:
		_ring_time_left = maxf(_ring_time_left - delta, 0.0)
		queue_redraw()


func _pulse() -> void:
	var stats := _player.character
	for enemy: Enemy in get_tree().get_nodes_in_group("enemies"):
		var offset := enemy.global_position - global_position
		if offset.length() <= stats.attack_radius + enemy.data.radius:
			enemy.take_hit(stats.attack_damage, offset.normalized() * stats.attack_knockback)
	_ring_time_left = RING_TIME
	queue_redraw()


func _draw() -> void:
	# Placeholder effect: a ring that grows to the attack radius and fades out.
	if _ring_time_left <= 0.0:
		return
	var progress := 1.0 - _ring_time_left / RING_TIME
	var radius := _player.character.attack_radius * progress
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, Color(1.0, 0.85, 0.4, 1.0 - progress), 6.0)
