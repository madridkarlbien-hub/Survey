# Author: Karl Bien Madrid
extends Node
## Remembers the current run between rooms: which room you are in, the reward
## waiting in it, and the player's stats, HP, level and XP.
## Always loaded (autoload), so every scene can reach it as `RunState`.

const DEFAULT_RUN: RunData = preload("res://data/runs/first_run.tres")

var run: RunData
## 1 for the first room. The boss room is `rooms_before_boss + 1`.
var room_number := 0
var current_room: RoomData
## Granted when the current room is cleared. Null in the first room.
var pending_reward: RewardData

var _saved_player := {}


func is_active() -> bool:
	return run != null


func start_run(run_data: RunData = DEFAULT_RUN) -> void:
	run = run_data
	room_number = 1
	pending_reward = null
	_saved_player = {}
	current_room = _pick_room(null)


func end_run() -> void:
	run = null
	room_number = 0
	current_room = null
	pending_reward = null
	_saved_player = {}


func total_rooms() -> int:
	return run.rooms_before_boss + 1


func is_boss_room() -> bool:
	return room_number > run.rooms_before_boss


## How much to multiply wave enemy counts by in the current room.
func difficulty_multiplier() -> float:
	if not current_room.scales_with_depth:
		return 1.0
	return 1.0 + run.difficulty_per_room * (room_number - 1)


## The rewards to show on this room's exit doors. A single null means the boss door.
func next_door_rewards() -> Array[RewardData]:
	if room_number == run.rooms_before_boss:
		return [null]
	var rewards := run.reward_pool.duplicate()
	rewards.shuffle()
	rewards.resize(mini(randi_range(run.min_doors, run.max_doors), rewards.size()))
	return rewards


## Move to the next room, which will grant `reward` when cleared.
func advance(reward: RewardData) -> void:
	room_number += 1
	pending_reward = reward
	current_room = run.boss_room if is_boss_room() else _pick_room(current_room)


func store_player(player: Player) -> void:
	_saved_player = {
		"character": player.character,
		"health": player.health,
		"level": player.level,
		"xp": player.xp,
		"boons": player.boons.duplicate(),
		"kills": player.kills,
	}


## Give a freshly spawned player the stats carried over from the last room.
func restore_player(player: Player) -> void:
	if _saved_player.is_empty():
		return
	player.character = _saved_player.character
	player.health = _saved_player.health
	player.level = _saved_player.level
	player.xp = _saved_player.xp
	player.boons = _saved_player.boons
	player.kills = _saved_player.kills


func _pick_room(avoid: RoomData) -> RoomData:
	# Never the same room twice in a row, when there is a choice.
	var options := run.room_pool.filter(func(room: RoomData) -> bool: return room != avoid)
	if options.is_empty():
		options = run.room_pool
	return options.pick_random()
