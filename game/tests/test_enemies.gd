# Author: Karl Bien Madrid
extends TestCase
## The corrupted creatures: their art, behaviors, projectiles, and the Bakunawa boss.

const EVIL := ["evil_tyanak", "evil_tikbalang", "evil_kapre", "evil_manananggal",
		"evil_white_lady", "evil_nuno_sa_punso", "evil_diwata", "evil_berberoka"]


func test_every_evil_creature_has_art_and_behavior() -> void:
	for key in EVIL:
		var data: EnemyData = load("res://data/enemies/%s.tres" % key)
		check(data.sprite != null, "%s has no sprite" % key)
		check(data.max_health > 0 and data.move_speed > 0.0, "%s needs health and speed" % key)
		if data.behavior != "chase":
			check(data.attack_range > 0.0, "%s never uses its %s move (no range)" % [key, data.behavior])


func test_tyanak_leaps() -> void:
	var room := await start_quiet_room()
	var tyanak := spawn_enemy(room, Vector2(120, 0), _tough("evil_tyanak"))
	tyanak._cooldown_left = 0.0
	await wait_frames(2)
	check_eq(tyanak._act, Enemy.Act.WINDUP, "Tyanak should wind up when close")
	await wait_seconds(0.4)
	check_eq(tyanak._act, Enemy.Act.ACTION, "then leap")
	check(tyanak.velocity.length() > 300.0, "leap is fast (%.0f)" % tyanak.velocity.length())


func test_tikbalang_charges_where_it_aimed() -> void:
	var room := await start_quiet_room()
	var player: Player = room.get_node("Player")
	var tikbalang := spawn_enemy(room, Vector2(300, 0), _tough("evil_tikbalang"))
	tikbalang._cooldown_left = 0.0
	await wait_frames(2)
	check_eq(tikbalang._act, Enemy.Act.WINDUP, "Tikbalang should wind up")
	player.global_position += Vector2(0, 200) # sidestep during the warning
	await wait_seconds(0.75)
	check_eq(tikbalang._act, Enemy.Act.ACTION, "then charge")
	check(tikbalang.velocity.x < -400.0 and absf(tikbalang.velocity.y) < 1.0,
			"charge keeps its original aim (velocity %s)" % tikbalang.velocity)


func test_kapre_throws_embers_that_hurt() -> void:
	var room := await start_quiet_room()
	var player: Player = room.get_node("Player")
	var kapre := spawn_enemy(room, Vector2(300, 0), _tough("evil_kapre"))
	kapre._cooldown_left = 0.0
	await wait_seconds(0.6)
	var shots := tree.get_nodes_in_group("enemy_projectiles")
	check_eq(shots.size(), 1, "one ember thrown")
	await wait_seconds(1.5)
	check_eq(player.health, player.character.max_health - 8, "ember damage")


func test_projectiles_respect_safety_window() -> void:
	var room := await start_quiet_room()
	var player: Player = room.get_node("Player")
	player.take_damage(5)
	check(not player.try_damage(8), "no projectile damage right after a hit")
	check_eq(player.health, player.character.max_health - 5, "health unchanged")


func test_diwata_shoots_a_fan() -> void:
	var room := await start_quiet_room()
	var diwata := spawn_enemy(room, Vector2(350, 0), _tough("evil_diwata"))
	diwata._cooldown_left = 0.0
	await wait_seconds(0.6)
	check_eq(tree.get_nodes_in_group("enemy_projectiles").size(), 5, "five petals")


func test_nuno_curse_follows_the_player() -> void:
	var room := await start_quiet_room()
	var player: Player = room.get_node("Player")
	var nuno := spawn_enemy(room, Vector2(400, 0), _tough("evil_nuno_sa_punso"))
	nuno._cooldown_left = 0.0
	await wait_seconds(0.6)
	player.global_position = Vector2(0, 300)
	await wait_seconds(1.0)
	var shots := tree.get_nodes_in_group("enemy_projectiles")
	check_eq(shots.size(), 1, "one curse orb")
	if shots.size() == 1:
		check(shots[0].velocity.y > 20.0, "curse orb should turn toward the player (%s)" % shots[0].velocity)


func test_white_lady_reappears_near_the_player() -> void:
	var room := await start_quiet_room()
	var player: Player = room.get_node("Player")
	var lady := spawn_enemy(room, Vector2(700, 0), _tough("evil_white_lady"))
	lady._cooldown_left = 0.0
	await wait_seconds(0.45)
	check(not lady.is_targetable(), "faded out while teleporting")
	await wait_seconds(0.7)
	check(lady.is_targetable(), "solid again after reappearing")
	var distance := lady.global_position.distance_to(player.global_position)
	check(distance < 220.0, "should reappear close to the player (%.0f px away)" % distance)


func test_manananggal_splits_on_death() -> void:
	var room := await start_quiet_room()
	spawn_enemy(room, Vector2(300, 0), load("res://data/enemies/evil_manananggal.tres"))
	await wait_frames(1)
	kill_all_enemies()
	await wait_frames(2)
	var enemies := tree.get_nodes_in_group("enemies")
	check_eq(enemies.size(), 1, "the torso keeps going")
	if enemies.size() == 1:
		check_eq(enemies[0].data.display_name, "Evil Manananggal (torso)", "torso data")


func test_berberoka_pulls_the_player_in() -> void:
	var room := await start_quiet_room()
	var player: Player = room.get_node("Player")
	var berberoka := spawn_enemy(room, Vector2(300, 0), _tough("evil_berberoka"))
	berberoka._cooldown_left = 0.0
	var start := player.global_position
	await wait_seconds(1.5)
	check(player.global_position.x > start.x + 60.0, "player should be dragged toward her (moved %.0f px)" % (player.global_position.x - start.x))


func test_bakunawa_cycles_its_attacks() -> void:
	var room := await start_quiet_room()
	var player: Player = room.get_node("Player")
	player.health = 100000
	player.get_node("Shockwave").process_mode = Node.PROCESS_MODE_DISABLED
	var boss: BakunawaBoss = spawn_enemy(room, Vector2(400, 0), load("res://data/enemies/bakunawa.tres"))
	await wait_seconds(2.0)
	check_eq(boss._move, BakunawaBoss.Move.BITE_WINDUP, "first attack is the bite")
	await wait_seconds(3.8) # bite, pause, then two fireball rings
	# A shot or two may already have hit the player, who is right next to the boss after its bite.
	var shots := tree.get_nodes_in_group("enemy_projectiles").size()
	check(shots >= BakunawaBoss.RING_COUNT - 3, "moonfire ring (%d shots in the air)" % shots)
	await wait_seconds(2.6) # pause, then the summon
	var tyanak := tree.get_nodes_in_group("enemies").filter(func(e: Enemy) -> bool: return e != boss)
	check_eq(tyanak.size(), BakunawaBoss.SUMMON_COUNT, "summoned Tyanak")


func test_bakunawa_enrages_below_half_health() -> void:
	var room := await start_quiet_room()
	var boss: BakunawaBoss = spawn_enemy(room, Vector2(600, 0), load("res://data/enemies/bakunawa.tres"))
	await wait_frames(1)
	check(not boss.is_enraged(), "calm at full health")
	boss.hurt(400.0)
	check(boss.is_enraged(), "enraged below half")
	boss._swim()
	check(is_equal_approx(boss._move_left, BakunawaBoss.ATTACK_PAUSE * BakunawaBoss.ENRAGED_PAUSE_SCALE), "shorter pauses")


func test_boss_bar_shows_in_hud() -> void:
	var room := await start_quiet_room()
	spawn_enemy(room, Vector2(600, 0), load("res://data/enemies/bakunawa.tres"))
	await wait_frames(3)
	check(room.get_node("HUD/BossBar").visible, "boss bar should show")
	check_eq(room.get_node("HUD/BossBar/BossName").text, "Bakunawa", "boss name")


func test_room_clear_removes_projectiles() -> void:
	var tiny := RoomData.new()
	tiny.clear_mode = RoomData.ClearMode.SURVIVE
	tiny.survive_time = 1.2
	tiny.wave_set = load("res://tests/fixtures/test_waves.tres")
	var room := await start_room(tiny)
	room.get_node("Player").health = 100000
	var kapre := spawn_enemy(room, Vector2(400, 0), _tough("evil_kapre"))
	kapre._cooldown_left = 0.0
	await wait_seconds(0.8)
	check(tree.get_nodes_in_group("enemy_projectiles").size() > 0, "an ember is in the air")
	await wait_seconds(0.6)
	check_eq(tree.get_nodes_in_group("enemy_projectiles").size(), 0, "embers vanish on clear")


func test_rooms_respect_depth() -> void:
	RunState.start_run()
	for i in RunState.run.rooms_before_boss - 1:
		var room := RunState.current_room
		check(room.min_depth <= RunState.room_number and RunState.room_number <= room.max_depth,
				"%s shouldn't appear in room %d" % [room.display_name, RunState.room_number])
		RunState.advance(null)


## A sturdy copy of an enemy, so the shockwave doesn't end the test early.
func _tough(key: String) -> EnemyData:
	var data: EnemyData = load("res://data/enemies/%s.tres" % key).duplicate()
	data.max_health = 10000
	return data
