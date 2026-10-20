# Author: Karl Bien Madrid
class_name TestCase
extends RefCounted
## Base class for automated tests. Test methods start with "test_" and may use await.
## Run all tests with tools/run_tests.sh.

const ROOM_SCENE := "res://scenes/rooms/test_room.tscn"
const ENEMY_SCENE := "res://scenes/enemies/enemy.tscn"
const PLACEHOLDER_ENEMY := "res://data/enemies/corrupted_spirit.tres"

var tree: SceneTree
var failures: Array[String] = []

var _room: Node


func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func check_eq(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		failures.append("%s (expected %s, got %s)" % [message, expected, actual])


## Load the test room as the running scene, exactly like pressing F5.
func start_room() -> Node:
	_room = load(ROOM_SCENE).instantiate()
	tree.root.add_child(_room)
	tree.current_scene = _room
	await wait_frames(1)
	return _room


## The test room with no waves, so a test can place its own enemies.
func start_quiet_room() -> Node:
	var room := await start_room()
	room.get_node("WaveSpawner").stop()
	for enemy in tree.get_nodes_in_group("enemies"):
		enemy.queue_free()
	await wait_frames(1)
	return room


## Long tests use this so the level-up menu doesn't pause the game forever.
func auto_pick_upgrades(room: Node) -> void:
	var menu: LevelUpMenu = room.get_node("LevelUpMenu")
	room.get_node("Player").leveled_up.connect(func(_level: int) -> void: menu.choose.call_deferred(0))


func spawn_enemy(room: Node, offset_from_player: Vector2) -> Enemy:
	var player: Player = room.get_node("Player")
	var enemy: Enemy = load(ENEMY_SCENE).instantiate()
	enemy.setup(load(PLACEHOLDER_ENEMY), player)
	enemy.position = player.position + offset_from_player
	room.get_node("WaveSpawner").add_child(enemy)
	return enemy


func wait_frames(count: int) -> void:
	for i in count:
		await tree.physics_frame


func wait_seconds(seconds: float) -> void:
	await wait_frames(ceili(seconds * Engine.physics_ticks_per_second))


## Called by the runner after each test.
func cleanup() -> void:
	tree.paused = false
	if is_instance_valid(_room):
		_room.queue_free()
	await tree.process_frame
