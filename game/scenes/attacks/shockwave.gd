# Author: Karl Bien Madrid
class_name Shockwave
extends Node2D
## The Tikbalang's stomp. Every few seconds, a ring of force hurts and pushes
## back all enemies within range. Boons add effects, and they all stack.
## Must be a child of the Player.

const FIRST_PULSE_DELAY := 1.0
const RING_TIME := 0.25
## Crescent Echo: delay and size of the follow-up shockwave.
const ECHO_DELAY := 0.4
const ECHO_RADIUS_SCALE := 0.7
## Undertow pulls enemies within this many times the shockwave's reach.
const UNDERTOW_REACH := 2.0
## Stormcall Stomp: how far lightning can jump between enemies.
const LIGHTNING_JUMP_RANGE := 220.0
const LIGHTNING_TIME := 0.15
const LIGHTNING_COLOR := Color(0.95, 0.95, 0.45)

var _player: Player
var _cooldown_left := FIRST_PULSE_DELAY
var _echo_left := -1.0
var _ring_time_left := 0.0
var _ring_radius := 0.0
var _bolts: Array[PackedVector2Array] = []
var _bolt_time_left := 0.0


func _ready() -> void:
	_player = get_parent()


func _physics_process(delta: float) -> void:
	if _player.health <= 0:
		return
	_cooldown_left -= delta
	if _cooldown_left <= 0.0:
		_cooldown_left += _player.character.attack_cooldown
		_pulse()
		if _player.get_boon("crescent_echo"):
			_echo_left = ECHO_DELAY
	if _echo_left >= 0.0:
		_echo_left -= delta
		if _echo_left < 0.0:
			_pulse(ECHO_RADIUS_SCALE, _player.get_boon("crescent_echo").power)
	if _ring_time_left > 0.0 or _bolt_time_left > 0.0:
		_ring_time_left = maxf(_ring_time_left - delta, 0.0)
		_bolt_time_left = maxf(_bolt_time_left - delta, 0.0)
		queue_redraw()


func _pulse(radius_scale := 1.0, damage_scale := 1.0) -> void:
	var stats := _player.character
	var radius := stats.attack_radius * radius_scale
	var damage := stats.attack_damage * damage_scale * fury_multiplier()
	var undertow := _player.get_boon("undertow")
	var hit_enemies: Array[Enemy] = []
	for enemy: Enemy in get_tree().get_nodes_in_group("enemies"):
		var offset := enemy.global_position - global_position
		var reach := radius + enemy.data.radius
		if offset.length() <= reach:
			enemy.take_hit(make_hit(damage, offset.normalized() * stats.attack_knockback))
			hit_enemies.append(enemy)
		elif undertow and offset.length() <= reach * UNDERTOW_REACH:
			enemy.push(-offset.normalized() * undertow.power)
	_chain_lightning(hit_enemies)
	_ring_radius = radius
	_ring_time_left = RING_TIME
	queue_redraw()


## Build the hit for one enemy, adding every effect from the player's boons.
func make_hit(damage: float, push: Vector2) -> Hit:
	var hit := Hit.new(damage, push)
	var tidal := _player.get_boon("tidal_stomp")
	if tidal:
		hit.push *= 1.0 + tidal.power
	var sunfire := _player.get_boon("sunfire_stomp")
	if sunfire:
		hit.burn_dps = sunfire.power
		hit.burn_time = sunfire.duration
	var moonlit := _player.get_boon("moonlit_stomp")
	if moonlit:
		hit.slow_amount = moonlit.power
		hit.slow_time = moonlit.duration
	var riptide := _player.get_boon("riptide")
	if riptide:
		hit.wall_damage = riptide.power
	return hit


## Warrior's Fury: extra damage while below half health.
func fury_multiplier() -> float:
	var fury := _player.get_boon("warriors_fury")
	if fury and _player.health < _player.character.max_health / 2.0:
		return 1.0 + fury.power
	return 1.0


func _chain_lightning(hit_enemies: Array[Enemy]) -> void:
	# Stormcall Stomp: from the first enemy hit, lightning jumps to the nearest
	# enemies that weren't hit, one after another.
	var storm := _player.get_boon("stormcall_stomp")
	if storm == null or hit_enemies.is_empty():
		return
	var struck: Array[Enemy] = hit_enemies.duplicate()
	var current: Enemy = hit_enemies[0]
	var bolt := PackedVector2Array([current.global_position])
	for jump in storm.count:
		var next := _nearest_enemy(current.global_position, struck)
		if next == null:
			break
		bolt.append(next.global_position)
		struck.append(next)
		next.take_hit(Hit.new(storm.power))
		current = next
	if bolt.size() > 1:
		_bolts = [bolt]
		_bolt_time_left = LIGHTNING_TIME


func _nearest_enemy(from: Vector2, exclude: Array[Enemy]) -> Enemy:
	var best: Enemy = null
	var best_distance := LIGHTNING_JUMP_RANGE
	for enemy: Enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy in exclude or enemy.health <= 0.0:
			continue
		var distance := from.distance_to(enemy.global_position)
		if distance <= best_distance:
			best = enemy
			best_distance = distance
	return best


func _draw() -> void:
	# Placeholder effects: a ring that grows and fades, and lightning lines.
	if _ring_time_left > 0.0:
		var progress := 1.0 - _ring_time_left / RING_TIME
		draw_arc(Vector2.ZERO, _ring_radius * progress, 0.0, TAU, 48,
				Color(1.0, 0.85, 0.4, 1.0 - progress), 6.0)
	if _bolt_time_left > 0.0:
		for bolt in _bolts:
			var points := PackedVector2Array()
			for point in bolt:
				points.append(to_local(point))
			draw_polyline(points, LIGHTNING_COLOR, 3.0)
