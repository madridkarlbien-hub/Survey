# Author: Karl Bien Madrid
extends SceneTree
## Plays a scripted run of the test room and saves screenshots of key moments
## to game/screenshots/. Start it with tools/take_screenshots.sh.

const OUT_DIR := "res://screenshots/"
const MAX_SECONDS := 90.0

var _room: Node
var _player: Player
var _menu: LevelUpMenu
var _frames := 0
var _taken := {}
var _busy := false


func _initialize() -> void:
	seed(12345)
	_room = load("res://scenes/rooms/test_room.tscn").instantiate()
	root.add_child(_room)
	current_scene = _room
	_player = _room.get_node("Player")
	_menu = _room.get_node("LevelUpMenu")


func _process(_delta: float) -> bool:
	_frames += 1
	if _busy or _frames < 2:
		return false
	var seconds := _frames / 60.0
	# Stay at full health so the run lasts long enough for every shot.
	_player.health = _player.character.max_health
	# Walk in a slow circle so the screenshots aren't all from the center.
	_set_input(Vector2.RIGHT.rotated(seconds * 0.5))

	if _menu.visible:
		_shoot_menu()
	elif _frames == 30:
		_shoot("01_start")
	elif seconds > 20.0 and not _taken.has("02_shockwave") and _ring_visible():
		_shoot("02_shockwave")
	elif seconds > 30.0 and not _taken.has("03_xp_orbs") and get_nodes_in_group("xp_orbs").size() >= 5:
		_shoot("03_xp_orbs")
	elif seconds > 75.0 and not _taken.has("05_big_wave") and _ring_visible():
		_shoot("05_big_wave")

	if _taken.size() >= 5 or seconds > MAX_SECONDS:
		print("Saved: ", _taken.keys())
		quit()
	return false


func _shoot_menu() -> void:
	_busy = true
	if not _taken.has("04_level_up_menu"):
		await _shoot("04_level_up_menu")
	_menu.choose(0)
	_busy = false


func _ring_visible() -> bool:
	# Mid-expansion, so the ring is big and still bright.
	var left: float = _player.get_node("Shockwave")._ring_time_left
	return left > 0.08 and left < 0.13


func _set_input(direction: Vector2) -> void:
	for action in ["move_left", "move_right", "move_up", "move_down"]:
		Input.action_release(action)
	if direction.x < -0.3: Input.action_press("move_left")
	if direction.x > 0.3: Input.action_press("move_right")
	if direction.y < -0.3: Input.action_press("move_up")
	if direction.y > 0.3: Input.action_press("move_down")


func _shoot(shot_name: String) -> void:
	_taken[shot_name] = true
	# Wait until this frame is actually drawn, so the picture matches the moment.
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path(OUT_DIR + shot_name + ".png"))
