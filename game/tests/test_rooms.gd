# Author: Karl Bien Madrid
extends TestCase
## Room clearing, rewards, doors, and moving through a run.


func test_defeat_all_room_clears_when_enemies_are_gone() -> void:
	var room := await start_room(_tiny_room(RoomData.ClearMode.DEFEAT_ALL))
	room.get_node("Player").health = 1_000_000
	await wait_seconds(1.2) # let all 3 enemies spawn
	check_eq(room.state, room.State.FIGHTING, "room should still be fighting while enemies live")
	kill_all_enemies()
	await wait_frames(3)
	check_eq(room.state, room.State.CLEARED, "room state after defeating everyone")
	var door_count: int = room.doors.size()
	check(door_count >= 2 and door_count <= 3, "should show 2-3 doors (got %d)" % door_count)


func test_survive_room_clears_after_timer() -> void:
	var room := await start_room(_tiny_room(RoomData.ClearMode.SURVIVE, 2.0))
	room.get_node("Player").health = 1_000_000
	await wait_seconds(1.5)
	check_eq(room.state, room.State.FIGHTING, "room state before the timer ends")
	await wait_seconds(0.8)
	check_eq(room.state, room.State.CLEARED, "room state after the timer")
	await wait_frames(2)
	check_eq(tree.get_nodes_in_group("enemies").size(), 0, "leftover enemies should vanish")


func test_walking_into_a_door_goes_to_next_room_with_stats() -> void:
	var room := await start_room(_tiny_room(RoomData.ClearMode.SURVIVE, 0.5))
	var player: Player = room.get_node("Player")
	player.add_xp(3)
	player.take_damage(20)
	var damage_upgrade := UpgradeData.new()
	damage_upgrade.stat = "attack_damage"
	damage_upgrade.amount = 7.0
	player.apply_upgrade(damage_upgrade)
	await wait_seconds(0.7)
	var door: Door = room.doors[0]
	var door_reward := door.reward # the door is freed when the scene changes
	player.global_position = door.global_position
	await wait_seconds(0.8)
	var next_room := tree.current_scene
	check(next_room != room, "should be in a new room")
	check_eq(RunState.room_number, 2, "room number")
	check_eq(RunState.pending_reward, door_reward, "reward waiting in the new room")
	var new_player: Player = next_room.get_node("Player")
	check_eq(new_player.health, new_player.character.max_health - 20, "HP carries over")
	check_eq(new_player.xp, 3, "XP carries over")
	check_eq(new_player.character.attack_damage, 17.0, "upgrades carry over")


func test_heal_reward_is_granted_on_clear() -> void:
	var room := await start_room(_tiny_room(RoomData.ClearMode.SURVIVE, 0.5))
	var player: Player = room.get_node("Player")
	RunState.pending_reward = load("res://data/rewards/heal.tres")
	player.take_damage(50)
	await wait_seconds(0.7)
	check_eq(player.health, player.character.max_health - 50 + 30, "HP after the heal reward")


func test_upgrade_reward_opens_menu() -> void:
	var room := await start_room(_tiny_room(RoomData.ClearMode.SURVIVE, 0.5))
	RunState.pending_reward = load("res://data/rewards/upgrade.tres")
	await wait_seconds(0.7)
	var menu: LevelUpMenu = room.get_node("LevelUpMenu")
	check(menu.visible, "upgrade menu should open")
	check(tree.paused, "game should pause for the pick")


func test_room_before_boss_has_one_boss_door() -> void:
	RunState.start_run()
	RunState.room_number = RunState.run.rooms_before_boss
	var rewards := RunState.next_door_rewards()
	check_eq(rewards.size(), 1, "door count before the boss")
	check(rewards[0] == null, "the only door should be the boss door")
	RunState.advance(rewards[0])
	check(RunState.is_boss_room(), "should now be in the boss room")
	check_eq(RunState.current_room, RunState.run.boss_room, "boss room data")


func test_rooms_do_not_repeat_back_to_back() -> void:
	RunState.start_run()
	for i in RunState.run.rooms_before_boss - 1:
		var before := RunState.current_room
		RunState.advance(null)
		check(RunState.current_room != before, "room %d repeated the previous room" % RunState.room_number)


func test_deeper_rooms_spawn_more() -> void:
	RunState.start_run()
	RunState.current_room = load("res://data/rooms/swarm_clearing.tres")
	check_eq(RunState.difficulty_multiplier(), 1.0, "room 1 multiplier")
	RunState.room_number = 6
	check(is_equal_approx(RunState.difficulty_multiplier(), 2.0), "room 6 should double enemy counts")
	RunState.current_room = RunState.run.boss_room
	check_eq(RunState.difficulty_multiplier(), 1.0, "boss room never scales")


func test_clearing_boss_room_wins_the_run() -> void:
	RunState.start_run()
	RunState.room_number = RunState.run.rooms_before_boss + 1
	var boss_room := _tiny_room(RoomData.ClearMode.SURVIVE, 0.5)
	RunState.current_room = boss_room
	_room = load(ROOM_SCENE).instantiate()
	tree.root.add_child(_room)
	tree.current_scene = _room
	_room.get_node("Player").health = 1_000_000
	await wait_seconds(0.7)
	check_eq(_room.state, _room.State.OVER, "room state after beating the boss")
	check(not RunState.is_active(), "run should be over")
	check_eq(_room.doors.size(), 0, "no doors after the boss")


func test_death_ends_the_run() -> void:
	var room := await start_room()
	var player: Player = room.get_node("Player")
	player.take_damage(9999)
	check(not RunState.is_active(), "run should end on death")
	check_eq(room.state, room.State.OVER, "room state after death")


## A small room with 3 placeholder enemies that spawn within 1 second.
func _tiny_room(mode: RoomData.ClearMode, survive_time := 45.0) -> RoomData:
	var wave := WaveData.new()
	wave.enemy = load(PLACEHOLDER_ENEMY)
	wave.enemy_count = 3
	wave.duration = 1.0
	var waves := WaveSet.new()
	waves.waves = [wave]
	var room := RoomData.new()
	room.clear_mode = mode
	room.survive_time = survive_time
	room.room_size = Vector2(2400, 1600)
	room.wave_set = waves
	return room
