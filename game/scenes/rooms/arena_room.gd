# Author: Karl Bien Madrid
extends Node2D
## One combat room of a run. Its size, waves and clear rule come from the
## current RoomData in RunState. When cleared, it grants the room's reward and
## opens doors to the next room. Clearing the boss room wins the run.
## When the run ends (victory or defeat), it returns to the hub.

const ROOM_SCENE := "res://scenes/rooms/arena_room.tscn"
const HUB_SCENE := "res://scenes/hub/hub.tscn"
const DOOR_SCENE := preload("res://scenes/rooms/door.tscn")
const RESTART_DELAY := 2.5
const VICTORY_DELAY := 4.0
## Second Life brings you back with this share of max HP.
const SECOND_LIFE_HEALTH := 0.3
const CLEARED_BANNER_TIME := 1.5
const DOOR_SPACING := 240.0
## How far below the top wall the doors appear.
const DOOR_INSET := 80.0

enum State { FIGHTING, CLEARED, OVER }

@export var wall_thickness := 32.0
@export var grid_spacing := 64.0
@export var floor_color := Color("2e2a24")
@export var grid_color := Color("3a352d")
@export var wall_color := Color("6b5640")

var room: RoomData
var state := State.FIGHTING
var doors: Array[Door] = []

var _room_size: Vector2
## Remembered at load, because the run ends (and RunState resets) on death or victory.
var _is_boss_room := false
var _room_label := ""
var _wall_rects: Array[Rect2] = []
var _time_in_room := 0.0

@onready var _player: Player = $Player
@onready var _spawner: WaveSpawner = $WaveSpawner
@onready var _xp_bar: ProgressBar = $HUD/XpBar
@onready var _stats_label: Label = $HUD/Stats
@onready var _hp_bar: ProgressBar = $HUD/HpBar
@onready var _hp_text: Label = $HUD/HpBar/HpText
@onready var _boon_label: Label = $HUD/Boons
@onready var _diwa_label: Label = $HUD/Diwa
@onready var _objective_label: Label = $HUD/Objective
@onready var _banner_label: Label = $HUD/Banner
@onready var _level_up_menu: LevelUpMenu = $LevelUpMenu


func _ready() -> void:
	if not RunState.is_active():
		RunState.start_run()
	room = RunState.current_room
	_room_size = room.room_size
	_is_boss_room = RunState.is_boss_room()
	_room_label = "BOSS" if _is_boss_room else "%d/%d" % [RunState.room_number, RunState.total_rooms()]
	_build_walls()

	RunState.restore_player(_player)
	_player.died.connect(_on_player_died)
	_level_up_menu.connect_player(_player)

	_spawner.wave_set = room.wave_set
	_spawner.loop_last_wave = room.clear_mode == RoomData.ClearMode.SURVIVE
	_spawner.count_multiplier = RunState.difficulty_multiplier()
	_spawner.start(_player, Rect2(-_room_size / 2.0, _room_size))


func _process(delta: float) -> void:
	if state == State.FIGHTING:
		_time_in_room += delta
		if _is_clear_condition_met():
			_clear_room()
	_update_hud()


func _is_clear_condition_met() -> bool:
	if _player.health <= 0:
		return false
	if room.clear_mode == RoomData.ClearMode.SURVIVE:
		return _time_in_room >= room.survive_time
	return _spawner.is_finished_spawning() and get_tree().get_node_count_in_group("enemies") == 0


func _clear_room() -> void:
	state = State.CLEARED
	_spawner.stop()
	# In SURVIVE rooms, leftover enemies vanish. Orbs fly to the player.
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.queue_free()
	for orb: XpOrb in get_tree().get_nodes_in_group("xp_orbs"):
		orb.attract()
	_player.heal(int(SaveData.bonus("room_clear_heal")))
	_grant_reward(RunState.pending_reward)
	SaveData.save_game()
	if _is_boss_room:
		_win_run()
		return
	_show_banner("Room cleared!", CLEARED_BANNER_TIME)
	_open_doors()


func _grant_reward(reward: RewardData) -> void:
	if reward == null:
		return
	match reward.kind:
		RewardData.Kind.UPGRADE:
			_level_up_menu.offer_upgrade()
		RewardData.Kind.HEAL:
			_player.heal(int(reward.amount))
		RewardData.Kind.BONUS_XP:
			_player.add_xp(int(reward.amount))
		RewardData.Kind.BOON:
			_level_up_menu.offer_boon(reward.deity)


func _open_doors() -> void:
	var rewards := RunState.next_door_rewards()
	var first_x := -DOOR_SPACING * (rewards.size() - 1) / 2.0
	for i in rewards.size():
		var door: Door = DOOR_SCENE.instantiate()
		door.reward = rewards[i]
		door.position = Vector2(first_x + i * DOOR_SPACING, -_room_size.y / 2.0 + DOOR_INSET)
		door.entered.connect(_on_door_entered)
		add_child(door)
		doors.append(door)


func _on_door_entered(reward: RewardData) -> void:
	if state != State.CLEARED:
		return
	state = State.OVER
	RunState.store_player(_player)
	RunState.advance(reward)
	get_tree().change_scene_to_file.call_deferred(ROOM_SCENE)


func _win_run() -> void:
	state = State.OVER
	SaveData.wins += 1
	_end_run("Victory!\nRun complete", VICTORY_DELAY)


func _on_player_died() -> void:
	if SaveData.level_of("second_life") > 0 and not RunState.second_life_used:
		RunState.second_life_used = true
		_player.revive(SECOND_LIFE_HEALTH)
		_show_banner("Bathala grants you a second life!", CLEARED_BANNER_TIME)
		return
	state = State.OVER
	_player.set_physics_process(false)
	_spawner.stop()
	_end_run("Defeated!", RESTART_DELAY)


## Record the run, show the result, then return to the hub.
func _end_run(title: String, delay: float) -> void:
	SaveData.runs += 1
	SaveData.save_game()
	_show_banner("%s\n+%d Diwa" % [title, RunState.run_diwa])
	RunState.end_run()
	await get_tree().create_timer(delay).timeout
	get_tree().change_scene_to_file(HUB_SCENE)


func _show_banner(text: String, hide_after := 0.0) -> void:
	_banner_label.text = text
	_banner_label.show()
	if hide_after > 0.0:
		await get_tree().create_timer(hide_after).timeout
		if _banner_label.text == text:
			_banner_label.hide()


func _update_hud() -> void:
	_xp_bar.max_value = _player.xp_to_next_level()
	_xp_bar.value = _player.xp
	_hp_bar.max_value = _player.character.max_health
	_hp_bar.value = _player.health
	_hp_text.text = "HP %d / %d" % [_player.health, _player.character.max_health]
	_stats_label.text = "Lv %d    Room %s" % [_player.level, _room_label]
	_diwa_label.text = "Diwa %d" % SaveData.diwa
	_boon_label.text = "\n".join(_player.boons.map(func(boon: BoonData) -> String: return boon.display_name))
	_objective_label.text = _objective_text()


func _objective_text() -> String:
	match state:
		State.CLEARED:
			return "Choose a door"
		State.OVER:
			return ""
	if room.clear_mode == RoomData.ClearMode.SURVIVE:
		var left := ceili(maxf(room.survive_time - _time_in_room, 0.0))
		return "Survive  %d:%02d" % [left / 60, left % 60]
	var text := "Defeat the boss and its minions" if _is_boss_room else "Defeat all enemies"
	if _spawner.is_finished_spawning():
		text += "  -  %d left" % get_tree().get_node_count_in_group("enemies")
	return text


func _build_walls() -> void:
	_wall_rects = RoomWalls.build(self, _room_size, wall_thickness)
	RoomWalls.limit_camera(_player.get_node("Camera2D"), _room_size, wall_thickness)
	queue_redraw()


func _draw() -> void:
	var half := _room_size / 2.0
	draw_rect(Rect2(-half, _room_size), floor_color)
	# Grid lines make movement easy to see while there is no real art yet.
	var x := -half.x
	while x <= half.x:
		draw_line(Vector2(x, -half.y), Vector2(x, half.y), grid_color)
		x += grid_spacing
	var y := -half.y
	while y <= half.y:
		draw_line(Vector2(-half.x, y), Vector2(half.x, y), grid_color)
		y += grid_spacing
	for rect in _wall_rects:
		draw_rect(rect, wall_color)
