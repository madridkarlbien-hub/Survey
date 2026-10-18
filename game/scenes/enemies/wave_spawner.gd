# Author: Karl Bien Madrid
class_name WaveSpawner
extends Node2D
## Spawns enemies in waves just outside the camera view around the target.

signal wave_started(wave_number: int)

@export var wave_set: WaveSet
@export var enemy_scene: PackedScene
## Hard cap so huge waves can't overload the laptop.
@export var max_enemies: int = 300
## Extra distance beyond the screen edge where enemies appear.
@export var spawn_margin: float = 64.0

var wave_number := 0

var _target: Node2D
var _bounds: Rect2
var _wave: WaveData
var _spawned_this_wave := 0
var _spawn_timer := 0.0
var _wave_time_left := 0.0


## Begin wave 1. Enemies chase `target` and always spawn inside `play_area`.
func start(target: Node2D, play_area: Rect2) -> void:
	_target = target
	_bounds = play_area.grow(-spawn_margin)
	_next_wave()


func stop() -> void:
	set_process(false)


func _process(delta: float) -> void:
	if _wave == null:
		return
	_wave_time_left -= delta
	_spawn_timer -= delta
	# Spread the wave's enemies evenly across its duration.
	var interval := _wave.duration / maxi(_wave.enemy_count, 1)
	while _spawn_timer <= 0.0 and _spawned_this_wave < _wave.enemy_count:
		_spawn(_wave.enemy)
		_spawned_this_wave += 1
		_spawn_timer += interval
	if _wave_time_left <= 0.0:
		_next_wave()


func _next_wave() -> void:
	wave_number += 1
	var index := mini(wave_number - 1, wave_set.waves.size() - 1)
	_wave = wave_set.waves[index]
	_spawned_this_wave = 0
	_spawn_timer = 0.0
	_wave_time_left = _wave.duration
	wave_started.emit(wave_number)


func _spawn(enemy_data: EnemyData) -> void:
	if get_tree().get_node_count_in_group("enemies") >= max_enemies:
		return
	var enemy: Enemy = enemy_scene.instantiate()
	enemy.setup(enemy_data, _target)
	# Position it before adding, so it never appears at the room's center for a frame.
	enemy.position = to_local(_pick_spawn_point())
	add_child(enemy)


func _pick_spawn_point() -> Vector2:
	# A random point on a circle just past the screen corners, kept inside the room.
	var radius := get_viewport_rect().size.length() / 2.0 + spawn_margin
	var point := _target.global_position + Vector2.RIGHT.rotated(randf() * TAU) * radius
	return point.clamp(_bounds.position, _bounds.end)
