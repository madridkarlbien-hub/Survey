# Author: Karl Bien Madrid
extends TestCase
## The hub, Diwa, Bathala's shrine, permanent upgrades, and saving.


func test_hub_is_peaceful() -> void:
	var hub := await start_hub()
	var shockwave: Shockwave = hub.get_node("Player/Shockwave")
	check_eq(shockwave.process_mode, Node.PROCESS_MODE_DISABLED, "no shockwave in the hub")
	check(not RunState.is_active(), "no run while in the hub")


func test_gate_starts_a_run() -> void:
	var hub := await start_hub()
	var player: Player = hub.get_node("Player")
	player.global_position = hub.get_node("RunGate").global_position
	await wait_seconds(0.8)
	check(RunState.is_active(), "walking into the gate should start a run")
	check_eq(RunState.room_number, 1, "room number")
	check(tree.current_scene != hub and tree.current_scene.has_node("WaveSpawner"),
			"should be in the first combat room")


func test_shrine_prompt_only_near_bathala() -> void:
	var hub := await start_hub()
	var prompt: Label = hub.get_node("HubHUD/Prompt")
	await wait_frames(2)
	check(not prompt.visible, "no prompt at the start position")
	hub.get_node("Player").global_position = hub.get_node("Bathala").global_position + Vector2(0, 80)
	await wait_frames(2)
	check(prompt.visible, "prompt should show next to Bathala")


func test_shrine_buys_upgrades() -> void:
	var hub := await start_hub()
	var shrine: ShrineMenu = hub.get_node("ShrineMenu")
	SaveData.diwa = 25
	shrine.open()
	check(tree.paused, "shrine should pause the hub")
	check(shrine.buy(0), "should afford Tibay level 1 (10 Diwa)")
	check_eq(SaveData.level_of("max_health"), 1, "Tibay level")
	check_eq(SaveData.diwa, 15, "Diwa after buying")
	check(not shrine.buy(0), "can't afford Tibay level 2 (20 Diwa)")
	check_eq(SaveData.diwa, 15, "Diwa unchanged after a failed buy")
	shrine.close()
	check(not tree.paused, "closing the shrine resumes the hub")


func test_upgrades_stop_at_max_level() -> void:
	SaveData.reset()
	var second_life: MetaUpgradeData = SaveData.SHRINE.find("second_life")
	SaveData.diwa = 1000
	check(SaveData.buy(second_life), "first level")
	check(not SaveData.buy(second_life), "Second Life has only one level")
	check_eq(SaveData.next_cost(second_life), -1, "maxed cost")


func test_permanent_upgrades_apply_to_runs() -> void:
	SaveData.reset()
	SaveData.levels = {"max_health": 2, "attack_damage": 1, "move_speed": 3}
	RunState.start_run()
	RunState.current_room = load(ENDLESS_ROOM)
	_room = load(ROOM_SCENE).instantiate()
	tree.root.add_child(_room)
	tree.current_scene = _room
	await wait_frames(1)
	var player: Player = _room.get_node("Player")
	check_eq(player.character.max_health, 90 + 20, "Tibay x2")
	check_eq(player.health, 110, "starts at the new max HP")
	check_eq(player.character.attack_damage, 10.0 + 2.0, "Lakas x1")
	check_eq(player.character.move_speed, 260.0 + 30.0, "Bilis x3")


func test_save_and_load() -> void:
	SaveData.reset()
	SaveData.diwa = 42
	SaveData.runs = 3
	SaveData.wins = 1
	SaveData.levels = {"diwa_chance": 2}
	SaveData.save_game()
	SaveData.reset()
	SaveData.load_game()
	check_eq(SaveData.diwa, 42, "Diwa after loading")
	check_eq(SaveData.runs, 3, "runs after loading")
	check_eq(SaveData.wins, 1, "wins after loading")
	check_eq(SaveData.level_of("diwa_chance"), 2, "upgrade level after loading")
	check(is_equal_approx(SaveData.bonus("diwa_chance"), 0.2), "Kapalaran bonus")


func test_enemies_drop_diwa_that_is_kept() -> void:
	var room := await start_quiet_room()
	var lucky: EnemyData = load(PLACEHOLDER_ENEMY).duplicate()
	lucky.diwa_chance = 1.0
	lucky.diwa_amount = 3
	spawn_enemy(room, Vector2(60, 0), lucky)
	await wait_frames(1)
	kill_all_enemies()
	await wait_frames(2)
	check_eq(tree.get_nodes_in_group("diwa_gems").size(), 1, "a Diwa gem should drop")
	await wait_seconds(0.5)
	check_eq(SaveData.diwa, 3, "Diwa collected")
	check_eq(RunState.run_diwa, 3, "Diwa counted for this run")


func test_room_clear_heal_from_biyaya() -> void:
	var tiny := RoomData.new()
	tiny.clear_mode = RoomData.ClearMode.SURVIVE
	tiny.survive_time = 0.5
	tiny.wave_set = load("res://tests/fixtures/test_waves.tres")
	var room := await start_room(tiny)
	SaveData.levels = {"room_clear_heal": 2}
	var player: Player = room.get_node("Player")
	player.take_damage(40)
	await wait_seconds(0.7)
	check_eq(player.health, 90 - 40 + 20, "Biyaya x2 heals 20 on clear")


func test_second_life_revives_once() -> void:
	var room := await start_quiet_room()
	SaveData.levels = {"second_life": 1}
	var player: Player = room.get_node("Player")
	player.take_damage(9999)
	check_eq(player.health, 27, "revived with 30% of 90 HP")
	check(RunState.is_active(), "run continues after Second Life")
	player._invulnerable_left = 0.0
	player.take_damage(9999)
	check_eq(player.health, 0, "no second revive")
	check(not RunState.is_active(), "run ends on the second defeat")


func test_run_end_returns_to_hub_and_counts_run() -> void:
	var room := await start_quiet_room()
	room.get_node("Player").take_damage(9999)
	check_eq(SaveData.runs, 1, "run counted")
	await wait_seconds(2.8)
	check_eq(tree.current_scene.name, &"Hub", "back in the realm of the gods")


func test_shrine_data_is_valid() -> void:
	var shrine: MetaUpgradePool = load("res://data/meta/shrine_upgrades.tres")
	check_eq(shrine.upgrades.size(), 6, "number of shrine upgrades")
	for upgrade in shrine.upgrades:
		check(upgrade.max_level() >= 1, "%s has no levels" % upgrade.display_name)
		for i in range(1, upgrade.costs.size()):
			check(upgrade.costs[i] > upgrade.costs[i - 1], "%s costs should rise each level" % upgrade.display_name)
