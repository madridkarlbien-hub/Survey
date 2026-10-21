# Author: Karl Bien Madrid
extends Node
## A bot that starts in the hub, plays one full run (6 rooms + boss) with an
## unbeatable player, returns to the hub and spends its Diwa at Bathala's shrine.
## Saves screenshots of key moments to game/screenshots/ and prints how long
## each room took. Uses its own save file. Started by tools/screenshots.gd
## (run tools/take_screenshots.sh).
## The player stands still and lets the shockwave do the work; after each room
## it walks into a boon door when there is one (else the first door) and always
## takes the first choice offered.

const OUT_DIR := "res://screenshots/"
const MAX_SECONDS := 900.0
const FPS := 60.0

var _frames := 0
var _taken := {}
var _busy := false
var _room: Node
var _room_frames := 0
var _cleared_frames := 0
var _log: Array[String] = []
var _hub_visits := 0
var _hub_frames := 0


func _ready() -> void:
	# Keep working while menus pause the game.
	process_mode = Node.PROCESS_MODE_ALWAYS
	seed(12345)
	for file in DirAccess.get_files_at(OUT_DIR):
		if file.ends_with(".png"):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(OUT_DIR + file))
	var save_data := get_tree().root.get_node("SaveData")
	save_data.save_path = "user://bot_save.json"
	save_data.reset()
	get_tree().change_scene_to_file("res://scenes/hub/hub.tscn")


func _process(_delta: float) -> void:
	_frames += 1
	if _busy or get_tree().current_scene == null or not get_tree().current_scene.has_node("Player"):
		return
	if get_tree().current_scene.name == &"Hub":
		_in_hub(get_tree().current_scene)
		return
	if get_tree().current_scene != _room:
		_enter_room(get_tree().current_scene)
	_room_frames += 1
	var player: Player = _room.get_node("Player")
	var menu: LevelUpMenu = _room.get_node("LevelUpMenu")
	var seconds_in_room := _room_frames / FPS
	player.health = player.character.max_health

	if menu.visible:
		_pick_upgrade(menu)
	elif _room.state == _room.State.OVER and _room.get_node("HUD/Banner").text.begins_with("Victory"):
		if not _taken.has("07_victory"):
			_log.append("Boss room  %.1fs" % (_room_frames / FPS))
			_log.append("Boons: %s" % [player.boons.map(func(boon: BoonData) -> String: return boon.display_name)])
			_log.append("Diwa this run: %d" % _run_state().run_diwa)
		_shoot_once("07_victory")
	elif _room.state == _room.State.CLEARED:
		_handle_cleared(player)
	elif _room_frames == 30 and _run_state().room_number == 1:
		_shoot("01_first_room")
	elif _run_state().room_number == 1 and seconds_in_room > 4.0 and _ring_visible(player):
		_shoot_once("02_shockwave")
	elif _room.room.clear_mode == RoomData.ClearMode.SURVIVE and seconds_in_room > 12.0:
		_shoot_once("05_survive_room")
	elif _room._is_boss_room and _boss_near(player) and _ring_visible(player):
		_shoot_once("06_boss")
	elif player.boons.size() >= 3 and seconds_in_room > 10.0 and _ring_visible(player):
		_shoot_once("09_boons_in_action")

	if _frames / FPS > MAX_SECONDS:
		_log.append("Stopped: time limit reached")
		_finish()


func _run_state() -> Node:
	return get_tree().root.get_node("RunState")


func _in_hub(hub: Node) -> void:
	if hub != _room:
		_room = hub
		_hub_visits += 1
		_hub_frames = 0
	_hub_frames += 1
	var player: Player = hub.get_node("Player")
	if _hub_visits == 1:
		if _hub_frames == 30:
			_shoot_once("10_hub")
		elif _hub_frames == 40:
			player.global_position = hub.get_node("RunGate").global_position
	elif _hub_frames == 30:
		player.global_position = hub.get_node("Bathala").global_position + Vector2(0, 90)
	elif _hub_frames == 40:
		_shoot_once("11_hub_near_bathala")
	elif _hub_frames == 50:
		hub.get_node("ShrineMenu").open()
	elif _hub_frames == 60:
		_shop(hub.get_node("ShrineMenu"))


func _shop(shrine: ShrineMenu) -> void:
	_busy = true
	await _shoot("12_shrine_before")
	# Buy the cheapest affordable level until nothing more is affordable.
	var save_data := get_tree().root.get_node("SaveData")
	var bought: Array[String] = []
	var spent := true
	while spent:
		spent = false
		for i in save_data.SHRINE.upgrades.size():
			if shrine.buy(i):
				bought.append(save_data.SHRINE.upgrades[i].display_name)
				spent = true
				break
	await _shoot("13_shrine_after")
	_log.append("Shrine: bought %s, %d Diwa left" % [bought, save_data.diwa])
	_finish()


func _enter_room(room: Node) -> void:
	_room = room
	_room_frames = 0
	_cleared_frames = 0


func _handle_cleared(player: Player) -> void:
	_cleared_frames += 1
	if _cleared_frames == 1:
		_log.append("Room %s  %-15s %-10s %5.1fs   Lv %d   HP %d/%d" % [
			_room._room_label, _room.room.display_name,
			RoomData.ClearMode.keys()[_room.room.clear_mode], _room_frames / FPS,
			player.level, player.health, player.character.max_health])
	var doors: Array[Door] = _room.doors
	if doors.is_empty():
		return
	if _cleared_frames == 60:
		# Stand just below the doors so they're on screen.
		player.global_position = doors[0].global_position + Vector2(_door_offset_x(doors), 260)
	elif _cleared_frames == 100:
		_shoot_once("04_doors")
	elif _cleared_frames == 110:
		player.global_position = _preferred_door(doors).global_position


func _door_offset_x(doors: Array[Door]) -> float:
	return (doors[-1].global_position.x - doors[0].global_position.x) / 2.0


func _preferred_door(doors: Array[Door]) -> Door:
	for door in doors:
		if door.reward and door.reward.kind == RewardData.Kind.BOON:
			return door
	return doors[0]


func _pick_upgrade(menu: LevelUpMenu) -> void:
	_busy = true
	if menu.choices[0] is BoonData:
		if not _taken.has("08_boon_menu"):
			await _shoot("08_boon_menu")
	elif not _taken.has("03_level_up_menu"):
		await _shoot("03_level_up_menu")
	menu.choose(0)
	_busy = false


func _finish() -> void:
	_busy = true
	print("\n".join(_log))
	print("Total time: %.1f s" % (_frames / FPS))
	print("Saved: ", _taken.keys())
	get_tree().quit()


func _ring_visible(player: Player) -> bool:
	# Mid-expansion, so the ring is big and still bright.
	var left: float = player.get_node("Shockwave")._ring_time_left
	return left > 0.08 and left < 0.13


func _boss_near(player: Player) -> bool:
	for enemy: Enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.data.show_health_bar and enemy.global_position.distance_to(player.global_position) < 300.0:
			return true
	return false


func _shoot_once(shot_name: String) -> void:
	if not _taken.has(shot_name):
		_busy = true
		await _shoot(shot_name)
		_busy = false


func _shoot(shot_name: String) -> void:
	_taken[shot_name] = true
	# Wait until this frame is actually drawn, so the picture matches the moment.
	await RenderingServer.frame_post_draw
	var image := get_tree().root.get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path(OUT_DIR + shot_name + ".png"))
