# Author: Karl Bien Madrid
class_name Enemy
extends CharacterBody2D
## A corrupted creature. Stats, art and behavior come from `data`: it chases the
## player and, depending on `data.behavior`, leaps, charges, shoots, teleports or
## pulls. Every special move has a short wind-up so the player can react.
## Can be burned, slowed and knocked back by boons. Drops XP (and maybe Diwa).

# Scenes are loaded when first needed (Godot caches them). Preloading them here
# would make a loop, because their scripts refer back to Player and Enemy.
const ENEMY_SCENE_PATH := "res://scenes/enemies/enemy.tscn"
const PROJECTILE_SCENE_PATH := "res://scenes/enemies/enemy_projectile.tscn"
const XP_ORB_SCENE_PATH := "res://scenes/pickups/xp_orb.tscn"
const DIWA_GEM_SCENE_PATH := "res://scenes/pickups/diwa_gem.tscn"
## Diwa lands a little to the side, so it doesn't hide under the XP orb.
const DIWA_DROP_OFFSET := Vector2(10, -8)
## How fast knockback wears off (pixels per second, per second).
const KNOCKBACK_DECAY := 1200.0
## Knockback slower than this no longer counts as "thrown" (for Riptide).
const THROWN_SPEED := 50.0
const HIT_FLASH_TIME := 0.1
const BURN_COLOR := Color(1.0, 0.55, 0.15)
const SLOW_TINT := Color(0.7, 0.8, 1.3)
const FLASH_TINT := Color(2.5, 2.5, 2.5)
const WARNING_COLOR := Color(1.0, 0.2, 0.2)
const ENEMY_LAYER := 4
## Teleport: how far from the player the enemy reappears.
const TELEPORT_MIN := 120.0
const TELEPORT_MAX := 170.0

enum Act { CHASE, WINDUP, ACTION }

var data: EnemyData
var target: Node2D
var health: float
## The room's floor; teleports and summons stay inside it (empty = no limit).
var play_area := Rect2()

var _knockback := Vector2.ZERO
var _flash_left := 0.0
var _burn_dps := 0.0
var _burn_left := 0.0
var _slow_amount := 0.0
var _slow_left := 0.0
var _wall_damage := 0.0
var _act := Act.CHASE
var _act_left := 0.0
var _cooldown_left := 0.0
var _action_dir := Vector2.RIGHT
var _sprite: Sprite2D


## Call before adding the enemy to the scene.
func setup(enemy_data: EnemyData, chase_target: Node2D) -> void:
	data = enemy_data
	target = chase_target
	health = data.max_health
	var shape := CircleShape2D.new()
	shape.radius = data.radius
	$CollisionShape2D.shape = shape
	# Start the first special move at a random moment, so a crowd doesn't act in sync.
	_cooldown_left = data.attack_cooldown * randf_range(0.3, 1.0)
	if data.sprite:
		_sprite = Sprite2D.new()
		_sprite.texture = data.sprite
		_sprite.scale = Vector2.ONE * (data.sprite_height / data.sprite.get_height())
		_sprite.position.y = -data.sprite_height * 0.25
		add_child(_sprite)


func _physics_process(delta: float) -> void:
	_update_status(delta)
	if health <= 0.0 or not is_instance_valid(target):
		return
	_cooldown_left -= delta
	velocity = _think(delta) + _knockback
	_knockback = _knockback.move_toward(Vector2.ZERO, KNOCKBACK_DECAY * delta)
	move_and_slide()
	_after_move()
	_check_wall_slam()
	_update_look()


func take_hit(hit: Hit) -> void:
	if health <= 0.0 or not is_targetable():
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


## False while faded out (White Lady teleporting).
func is_targetable() -> bool:
	return collision_layer != 0


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


## Multiplier from slowing effects (Moonlit Stomp).
func speed_factor() -> float:
	return 1.0 - _slow_amount if _slow_left > 0.0 else 1.0


## Decide this frame's movement. Behaviors and bosses work here.
func _think(delta: float) -> Vector2:
	var to_target := target.global_position - global_position
	var distance := to_target.length()
	var dir := to_target.normalized()
	match _act:
		Act.WINDUP:
			_act_left -= delta
			if _act_left <= 0.0:
				_start_action(dir)
			return Vector2.ZERO
		Act.ACTION:
			_act_left -= delta
			var move := _action_velocity(dir)
			if _act_left <= 0.0:
				_finish_action()
			return move
	if data.behavior != "chase" and _cooldown_left <= 0.0 and distance <= data.attack_range:
		_act = Act.WINDUP
		_act_left = data.windup_time
		# A charge is aimed when the wind-up starts, so the player can sidestep it.
		_action_dir = dir
		queue_redraw()
		return Vector2.ZERO
	return _move_velocity(dir, distance)


func _move_velocity(dir: Vector2, distance: float) -> Vector2:
	var speed := data.move_speed * speed_factor()
	if data.keep_distance > 0.0 and distance < data.keep_distance:
		# Shooters back away when you get too close, and hold still otherwise.
		return -dir * speed * 0.6 if distance < data.keep_distance * 0.7 else Vector2.ZERO
	return dir * speed


func _start_action(dir: Vector2) -> void:
	match data.behavior:
		"leap":
			_action_dir = dir
			_begin_action(data.action_time)
		"charge", "vortex":
			_begin_action(data.action_time)
		"ranged", "spread", "homing":
			_fire(dir)
			_finish_action()
		"teleport":
			collision_layer = 0
			_begin_action(data.action_time)
		_:
			_finish_action()


func _begin_action(seconds: float) -> void:
	_act = Act.ACTION
	_act_left = seconds
	queue_redraw()


func _action_velocity(dir: Vector2) -> Vector2:
	match data.behavior:
		"leap", "charge":
			return _action_dir * data.action_speed * speed_factor()
		"vortex":
			if target is Player:
				target.pull(-dir * data.pull_strength)
	return Vector2.ZERO


func _finish_action() -> void:
	if data.behavior == "teleport" and not is_targetable():
		_reappear_near_target()
	_act = Act.CHASE
	_cooldown_left = data.attack_cooldown
	queue_redraw()


func _reappear_near_target() -> void:
	var offset := Vector2.RIGHT.rotated(randf() * TAU) * randf_range(TELEPORT_MIN, TELEPORT_MAX)
	global_position = _inside_play_area(target.global_position + offset)
	collision_layer = ENEMY_LAYER


func _fire(dir: Vector2) -> void:
	var spread := deg_to_rad(data.projectile_spread)
	for i in data.projectile_count:
		var angle := 0.0 if data.projectile_count == 1 else -spread / 2.0 + spread * i / (data.projectile_count - 1)
		_shoot(dir.rotated(angle))


func _shoot(dir: Vector2) -> void:
	var shot: EnemyProjectile = load(PROJECTILE_SCENE_PATH).instantiate()
	shot.velocity = dir * data.projectile_speed
	shot.damage = data.projectile_damage
	shot.homing = data.projectile_homing
	shot.lifetime = data.projectile_lifetime
	shot.color = data.projectile_color
	shot.target = target
	shot.position = position + dir * (data.radius + 8.0)
	get_parent().add_child.call_deferred(shot)


## Add another enemy next to this one (Manananggal's torso, boss summons).
func _spawn_child(child_data: EnemyData, offset: Vector2) -> void:
	var scene: PackedScene = child_data.custom_scene if child_data.custom_scene else load(ENEMY_SCENE_PATH)
	var child: Enemy = scene.instantiate()
	child.setup(child_data, target)
	child.play_area = play_area
	child.position = get_parent().to_local(_inside_play_area(global_position + offset))
	get_parent().add_child.call_deferred(child)


func _inside_play_area(point: Vector2) -> Vector2:
	if play_area.has_area():
		return point.clamp(play_area.position, play_area.end)
	return point


## Called after moving each frame (the boss uses it to update its body).
func _after_move() -> void:
	if _act == Act.ACTION and data.behavior == "charge" and _hit_wall():
		_finish_action()


func _hit_wall() -> bool:
	for i in get_slide_collision_count():
		if get_slide_collision(i).get_collider() is StaticBody2D:
			return true
	return false


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


func _update_look() -> void:
	if _sprite == null:
		return
	var moving_left := target.global_position.x < global_position.x
	_sprite.flip_h = moving_left == data.sprite_faces_right
	var tint := Color.WHITE
	if _slow_left > 0.0:
		tint = SLOW_TINT
	if _flash_left > 0.0:
		tint = FLASH_TINT
	tint.a = 0.25 if not is_targetable() else 1.0
	_sprite.modulate = tint
	if _act != Act.CHASE:
		queue_redraw()


func _check_wall_slam() -> void:
	# Riptide: hitting a wall while still flying from a knockback hurts.
	if _wall_damage <= 0.0:
		return
	if _knockback.length() < THROWN_SPEED:
		_wall_damage = 0.0
		return
	if _hit_wall():
		var damage := _wall_damage
		_wall_damage = 0.0
		hurt(damage)


func _die() -> void:
	if target is Player:
		target.register_kill()
	_drop(XP_ORB_SCENE_PATH, data.xp_value, Vector2.ZERO)
	if randf() < data.diwa_chance + SaveData.bonus("diwa_chance"):
		_drop(DIWA_GEM_SCENE_PATH, data.diwa_amount, DIWA_DROP_OFFSET)
	if data.split_into:
		_spawn_child(data.split_into, Vector2.ZERO)
	queue_free()


func _drop(scene_path: String, value: int, offset: Vector2) -> void:
	var pickup: XpOrb = load(scene_path).instantiate()
	pickup.value = value
	pickup.position = position + offset
	get_parent().add_child.call_deferred(pickup)


func _draw() -> void:
	# A soft shadow grounds the sprite. Without art, a colored circle stands in.
	draw_set_transform(Vector2(0, data.radius * 0.6), 0.0, Vector2(1.0, 0.4))
	draw_circle(Vector2.ZERO, data.radius * 1.1, Color(0, 0, 0, 0.35))
	draw_set_transform(Vector2.ZERO)
	if _sprite == null:
		var body_color := data.placeholder_color
		if _slow_left > 0.0:
			body_color = body_color.lerp(SLOW_TINT, 0.5)
		if _flash_left > 0.0:
			body_color = Color.WHITE
		draw_circle(Vector2.ZERO, data.radius, body_color)
		draw_arc(Vector2.ZERO, data.radius, 0.0, TAU, 24, Color(0.9, 0.15, 0.2), 2.0)
	if _burn_left > 0.0:
		draw_arc(Vector2.ZERO, data.radius + 3.0, 0.0, TAU, 24, BURN_COLOR, 2.0)
	_draw_warning()
	if data.show_health_bar:
		var bar := Rect2(-data.radius, -data.sprite_height * 0.75 - 10.0, data.radius * 2.0, 6.0)
		draw_rect(bar, Color(0, 0, 0, 0.6))
		bar.size.x *= maxf(health, 0.0) / data.max_health
		draw_rect(bar, Color(0.9, 0.15, 0.2))


## Telegraphs, so every special move can be seen coming.
func _draw_warning() -> void:
	if _act == Act.WINDUP:
		draw_arc(Vector2.ZERO, data.radius + 6.0, 0.0, TAU, 24, WARNING_COLOR, 3.0)
		if data.behavior == "charge":
			draw_line(Vector2.ZERO, _action_dir * 160.0, Color(WARNING_COLOR, 0.6), 4.0)
		elif data.behavior in ["ranged", "spread", "homing"]:
			draw_circle(Vector2.ZERO, data.radius * 0.6, Color(data.projectile_color, 0.6))
	elif _act == Act.ACTION and data.behavior == "vortex":
		for ring in 3:
			draw_arc(Vector2.ZERO, data.radius + 20.0 + ring * 18.0, 0.0, TAU, 32, Color(0.4, 0.7, 1.0, 0.5), 2.0)
