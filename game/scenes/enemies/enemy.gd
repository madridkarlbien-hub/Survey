# Author: Karl Bien Madrid
class_name Enemy
extends CharacterBody2D
## A basic enemy that walks straight at its target. Stats come from `data`.
## Can be burned, slowed and knocked back by boons. Drops an XP orb when defeated.

const XP_ORB_SCENE := preload("res://scenes/pickups/xp_orb.tscn")
const DIWA_GEM_SCENE := preload("res://scenes/pickups/diwa_gem.tscn")
## Diwa lands a little to the side, so it doesn't hide under the XP orb.
const DIWA_DROP_OFFSET := Vector2(10, -8)
## How fast knockback wears off (pixels per second, per second).
const KNOCKBACK_DECAY := 1200.0
## Knockback slower than this no longer counts as "thrown" (for Riptide).
const THROWN_SPEED := 50.0
const HIT_FLASH_TIME := 0.1
const BURN_COLOR := Color(1.0, 0.55, 0.15)
const SLOW_COLOR := Color(0.7, 0.75, 1.0)

var data: EnemyData
var target: Node2D
var health: float

var _knockback := Vector2.ZERO
var _flash_left := 0.0
var _burn_dps := 0.0
var _burn_left := 0.0
var _slow_amount := 0.0
var _slow_left := 0.0
var _wall_damage := 0.0


## Call before adding the enemy to the scene.
func setup(enemy_data: EnemyData, chase_target: Node2D) -> void:
	data = enemy_data
	target = chase_target
	health = data.max_health
	var shape := CircleShape2D.new()
	shape.radius = data.radius
	$CollisionShape2D.shape = shape


func _physics_process(delta: float) -> void:
	_update_status(delta)
	if health <= 0.0 or not is_instance_valid(target):
		return
	var speed := data.move_speed * (1.0 - _slow_amount if _slow_left > 0.0 else 1.0)
	velocity = global_position.direction_to(target.global_position) * speed + _knockback
	_knockback = _knockback.move_toward(Vector2.ZERO, KNOCKBACK_DECAY * delta)
	move_and_slide()
	_check_wall_slam()


func take_hit(hit: Hit) -> void:
	if health <= 0.0:
		return
	push(hit.push)
	if hit.burn_time > 0.0:
		_burn_dps = maxf(_burn_dps, hit.burn_dps)
		_burn_left = maxf(_burn_left, hit.burn_time)
	if hit.slow_time > 0.0:
		_slow_amount = maxf(_slow_amount, hit.slow_amount)
		_slow_left = maxf(_slow_left, hit.slow_time)
	if hit.wall_damage > 0.0:
		_wall_damage = hit.wall_damage
	hurt(hit.damage)


func push(force: Vector2) -> void:
	_knockback += force * (1.0 - data.knockback_resistance)


## Lose health. `flash` is off for damage over time, so the enemy doesn't strobe.
func hurt(damage: float, flash := true) -> void:
	if health <= 0.0:
		return
	health -= damage
	if flash:
		_flash_left = HIT_FLASH_TIME
	queue_redraw()
	if health <= 0.0:
		_die()


func _update_status(delta: float) -> void:
	if _flash_left > 0.0:
		_flash_left = maxf(_flash_left - delta, 0.0)
		if _flash_left == 0.0:
			queue_redraw()
	if _slow_left > 0.0:
		_slow_left = maxf(_slow_left - delta, 0.0)
		if _slow_left == 0.0:
			_slow_amount = 0.0
			queue_redraw()
	if _burn_left > 0.0:
		_burn_left = maxf(_burn_left - delta, 0.0)
		hurt(_burn_dps * delta, false)
		if _burn_left == 0.0:
			_burn_dps = 0.0
			queue_redraw()


func _check_wall_slam() -> void:
	# Riptide: hitting a wall while still flying from a knockback hurts.
	if _wall_damage <= 0.0:
		return
	if _knockback.length() < THROWN_SPEED:
		_wall_damage = 0.0
		return
	for i in get_slide_collision_count():
		if get_slide_collision(i).get_collider() is StaticBody2D:
			var damage := _wall_damage
			_wall_damage = 0.0
			hurt(damage)
			return


func _die() -> void:
	if target is Player:
		target.register_kill()
	_drop(XP_ORB_SCENE, data.xp_value, Vector2.ZERO)
	if randf() < data.diwa_chance + SaveData.bonus("diwa_chance"):
		_drop(DIWA_GEM_SCENE, data.diwa_amount, DIWA_DROP_OFFSET)
	queue_free()


func _drop(scene: PackedScene, value: int, offset: Vector2) -> void:
	var pickup: XpOrb = scene.instantiate()
	pickup.value = value
	pickup.position = position + offset
	get_parent().add_child.call_deferred(pickup)


func _draw() -> void:
	# Placeholder art: a dark body with a red ring so enemies read as hostile.
	# Flashes white when hit, tints blue when slowed, and glows orange when burning.
	var body_color := data.placeholder_color
	if _slow_left > 0.0:
		body_color = body_color.lerp(SLOW_COLOR, 0.5)
	if _flash_left > 0.0:
		body_color = Color.WHITE
	draw_circle(Vector2.ZERO, data.radius, body_color)
	draw_arc(Vector2.ZERO, data.radius, 0.0, TAU, 24, Color(0.9, 0.15, 0.2), 2.0)
	if _burn_left > 0.0:
		draw_arc(Vector2.ZERO, data.radius + 3.0, 0.0, TAU, 24, BURN_COLOR, 2.0)
	if data.show_health_bar:
		var bar := Rect2(-data.radius, -data.radius - 14.0, data.radius * 2.0, 6.0)
		draw_rect(bar, Color(0, 0, 0, 0.6))
		bar.size.x *= maxf(health, 0.0) / data.max_health
		draw_rect(bar, Color(0.9, 0.15, 0.2))
