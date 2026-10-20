# Author: Karl Bien Madrid
class_name Enemy
extends CharacterBody2D
## A basic enemy that walks straight at its target. Stats come from `data`.
## Drops an XP orb when defeated.

const XP_ORB_SCENE := preload("res://scenes/pickups/xp_orb.tscn")
## How fast knockback wears off (pixels per second, per second).
const KNOCKBACK_DECAY := 1200.0
const HIT_FLASH_TIME := 0.1

var data: EnemyData
var target: Node2D
var health: float

var _knockback := Vector2.ZERO
var _flash_left := 0.0


## Call before adding the enemy to the scene.
func setup(enemy_data: EnemyData, chase_target: Node2D) -> void:
	data = enemy_data
	target = chase_target
	health = data.max_health
	var shape := CircleShape2D.new()
	shape.radius = data.radius
	$CollisionShape2D.shape = shape


func _physics_process(delta: float) -> void:
	if _flash_left > 0.0:
		_flash_left = maxf(_flash_left - delta, 0.0)
		if _flash_left == 0.0:
			queue_redraw()
	if not is_instance_valid(target):
		return
	var chase := global_position.direction_to(target.global_position) * data.move_speed
	velocity = chase + _knockback
	_knockback = _knockback.move_toward(Vector2.ZERO, KNOCKBACK_DECAY * delta)
	move_and_slide()


func take_hit(damage: float, push: Vector2) -> void:
	if health <= 0.0:
		return
	health -= damage
	_knockback += push
	_flash_left = HIT_FLASH_TIME
	queue_redraw()
	if health <= 0.0:
		_die()


func _die() -> void:
	var orb: XpOrb = XP_ORB_SCENE.instantiate()
	orb.value = data.xp_value
	orb.position = position
	get_parent().add_child(orb)
	queue_free()


func _draw() -> void:
	# Placeholder art: a dark body with a red ring so enemies read as hostile.
	# Flashes white for a moment when hit.
	var body_color := Color.WHITE if _flash_left > 0.0 else data.placeholder_color
	draw_circle(Vector2.ZERO, data.radius, body_color)
	draw_arc(Vector2.ZERO, data.radius, 0.0, TAU, 24, Color(0.9, 0.15, 0.2), 2.0)
