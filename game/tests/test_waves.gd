# Author: Karl Bien Madrid
extends TestCase
## Wave timing, spawn positions, and the enemy cap.


func test_waves_advance_and_spawn_off_screen() -> void:
	var room := await start_room()
	var player: Player = room.get_node("Player")
	var spawner: WaveSpawner = room.get_node("WaveSpawner")
	player.health = 1_000_000 # survive the whole test
	auto_pick_upgrades(room)
	var closest := [INF]
	spawner.child_entered_tree.connect(func(node: Node) -> void:
		if node is Enemy:
			closest[0] = minf(closest[0], node.global_position.distance_to(player.global_position)))
	await wait_seconds(16.0)
	check_eq(spawner.wave_number, 2, "wave after 16 seconds")
	check(closest[0] >= 700.0, "enemies should spawn off-screen (closest was %.0f px)" % closest[0])


func test_enemy_cap() -> void:
	var room := await start_room()
	var player: Player = room.get_node("Player")
	var spawner: WaveSpawner = room.get_node("WaveSpawner")
	player.health = 1_000_000
	player.get_node("Shockwave").set_physics_process(false)
	var flood := WaveData.new()
	flood.enemy = load(PLACEHOLDER_ENEMY)
	flood.enemy_count = 50
	flood.duration = 2.0
	var wave_set := WaveSet.new()
	wave_set.waves = [flood]
	spawner.max_enemies = 5
	spawner.wave_set = wave_set
	spawner.start(player, Rect2(-1600, -1200, 3200, 2400))
	await wait_seconds(2.5)
	check(tree.get_nodes_in_group("enemies").size() <= 5, "enemy count should never pass the cap")


func test_full_run_smoke() -> void:
	# Plays 30 seconds with an unbeatable player: nothing should crash, and the
	# shockwave should defeat enemies and earn XP.
	var room := await start_room()
	var player: Player = room.get_node("Player")
	player.health = 1_000_000
	auto_pick_upgrades(room)
	await wait_seconds(30.0)
	check(player.level > 1 or player.xp > 0, "player should have earned XP in 30 seconds")
