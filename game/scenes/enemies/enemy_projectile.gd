# Author: Karl Bien Madrid
class_name EnemyProjectile
extends Area2D
## A dodgeable shot fired by an enemy (Kapre embers, Diwata petals, Nuno curses,
## Bakunawa fireballs). Hurts the player on touch, vanishes on walls.

const RADIUS := 7.0

var velocity := Vector2.ZERO
var damage := 6
## Radians per second it can turn toward the target (0 = flies straight).
var homing := 0.0
var lifetime := 4.0
var color := Color(1.0, 0.5, 0.2)
var target: Node2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return
	if homing > 0.0 and is_instance_valid(target):
		var wanted := global_position.direction_to(target.global_position).angle()
		var turn := clampf(angle_difference(velocity.angle(), wanted), -homing * delta, homing * delta)
		velocity = velocity.rotated(turn)
	position += velocity * delta


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		body.try_damage(damage)
		queue_free()
	elif body is StaticBody2D:
		queue_free()


func _draw() -> void:
	# Placeholder effect: a glowing ball with a bright core.
	draw_circle(Vector2.ZERO, RADIUS + 4.0, Color(color, 0.3))
	draw_circle(Vector2.ZERO, RADIUS, color)
	draw_circle(Vector2.ZERO, RADIUS * 0.45, Color(1, 1, 0.9))
