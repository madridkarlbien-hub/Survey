# Author: Karl Bien Madrid
extends TestCase
## Deities, boon rewards, and every boon effect.

const DEITIES := ["apolaki", "mayari", "amanikable", "anitun_tabu"]


func test_every_deity_has_three_valid_boons() -> void:
	var known_effects: PackedStringArray = BoonData.new().get_property_list().filter(
			func(p: Dictionary) -> bool: return p.name == "effect")[0].hint_string.split(",")
	for key in DEITIES:
		var deity: DeityData = load("res://data/deities/%s.tres" % key)
		check_eq(deity.boons.size(), 3, "%s boon count" % key)
		for boon in deity.boons:
			check(boon.effect in known_effects, "%s has unknown effect %s" % [boon.display_name, boon.effect])
		var reward: RewardData = load("res://data/rewards/boon_%s.tres" % key)
		check_eq(reward.kind, RewardData.Kind.BOON, "%s reward kind" % key)
		check_eq(reward.deity, deity, "%s reward deity" % key)


func test_boon_reward_offers_that_deitys_boons() -> void:
	var room := await start_quiet_room()
	var player: Player = room.get_node("Player")
	var menu: LevelUpMenu = room.get_node("LevelUpMenu")
	var mayari: DeityData = load("res://data/deities/mayari.tres")
	menu.offer_boon(mayari)
	check(menu.visible and tree.paused, "boon menu should open and pause")
	check_eq(menu.choices.size(), 3, "number of boon choices")
	for choice in menu.choices:
		check(choice in mayari.boons, "%s is not one of Mayari's boons" % choice.display_name)
	var picked: BoonData = menu.choices[0]
	menu.choose(0)
	check(picked in player.boons, "picked boon should be owned")
	menu.offer_boon(mayari)
	check_eq(menu.choices.size(), 2, "owned boons shouldn't be offered again")
	check(not picked in menu.choices, "owned boon was offered again")


func test_owning_every_boon_falls_back_to_upgrade() -> void:
	var room := await start_quiet_room()
	var player: Player = room.get_node("Player")
	var menu: LevelUpMenu = room.get_node("LevelUpMenu")
	var apolaki: DeityData = load("res://data/deities/apolaki.tres")
	for boon in apolaki.boons:
		player.add_boon(boon)
	menu.offer_boon(apolaki)
	check(menu.choices[0] is UpgradeData, "should offer upgrades instead")


func test_stomp_boons_stack_on_one_hit() -> void:
	var room := await start_quiet_room()
	var player: Player = room.get_node("Player")
	for effect in ["sunfire_stomp", "moonlit_stomp", "tidal_stomp", "riptide"]:
		player.add_boon(_boon(effect))
	var hit: Hit = player.get_node("Shockwave").make_hit(10.0, Vector2(250, 0))
	check_eq(hit.burn_dps, 4.0, "burn from Sunfire Stomp")
	check_eq(hit.slow_amount, 0.4, "slow from Moonlit Stomp")
	check_eq(hit.push, Vector2(500, 0), "doubled push from Tidal Stomp")
	check_eq(hit.wall_damage, 10.0, "wall damage from Riptide")


func test_sunfire_burns_over_time() -> void:
	var room := await start_quiet_room()
	var player: Player = room.get_node("Player")
	player.add_boon(_boon("sunfire_stomp"))
	var shockwave: Shockwave = player.get_node("Shockwave")
	shockwave._cooldown_left = 999.0 # only the stomp below, no automatic ones
	var enemy := spawn_enemy(room, Vector2(60, 0), tough_enemy_data())
	await wait_frames(1)
	shockwave._pulse()
	check_eq(enemy.health, 990.0, "health right after the hit")
	await wait_seconds(1.0)
	check(enemy.health < 987.0 and enemy.health > 984.0, "about 4 burn damage per second (health %.1f)" % enemy.health)


func test_moonlit_slows() -> void:
	var room := await start_quiet_room()
	var player: Player = room.get_node("Player")
	player.add_boon(_boon("moonlit_stomp"))
	player.character.attack_knockback = 0.0
	var enemy := spawn_enemy(room, Vector2(100, 0), tough_enemy_data())
	await wait_frames(1)
	player.get_node("Shockwave")._pulse()
	await wait_frames(2)
	check(is_equal_approx(enemy.velocity.length(), 110.0 * 0.6), "enemy should move at 60%% speed (got %.0f)" % enemy.velocity.length())


func test_crescent_echo_hits_twice() -> void:
	var room := await start_quiet_room()
	var player: Player = room.get_node("Player")
	player.add_boon(_boon("crescent_echo"))
	player.character.attack_knockback = 0.0
	var enemy := spawn_enemy(room, Vector2(40, 0), tough_enemy_data())
	await wait_seconds(1.6) # first stomp at 1.0s, echo 0.4s later
	check_eq(enemy.health, 1000.0 - 10.0 - 5.0, "health after stomp + half-damage echo")


func test_undertow_pulls_enemies_in() -> void:
	var room := await start_quiet_room()
	var player: Player = room.get_node("Player")
	player.add_boon(_boon("undertow"))
	var enemy := spawn_enemy(room, Vector2(180, 0), tough_enemy_data())
	await wait_frames(1)
	player.get_node("Shockwave")._pulse()
	check_eq(enemy.health, 1000.0, "enemy outside the ring isn't damaged")
	check(enemy._knockback.x < -300.0, "enemy should be pulled toward the player")


func test_riptide_hurts_on_wall_slam() -> void:
	var room := await start_quiet_room()
	var player: Player = room.get_node("Player")
	var enemy := spawn_enemy(room, Vector2(1540, 0), tough_enemy_data()) # near the right wall
	await wait_frames(1)
	var hit := Hit.new(0.0, Vector2(800, 0))
	hit.wall_damage = 10.0
	enemy.take_hit(hit)
	await wait_seconds(0.3)
	check_eq(enemy.health, 990.0, "wall slam damage")
	await wait_seconds(0.3)
	check_eq(enemy.health, 990.0, "only one slam per knockback")


func test_stormcall_chains_lightning() -> void:
	var room := await start_quiet_room()
	var player: Player = room.get_node("Player")
	player.add_boon(_boon("stormcall_stomp"))
	player.character.attack_knockback = 0.0
	var tough := tough_enemy_data()
	var near := spawn_enemy(room, Vector2(60, 0), tough)
	var second := spawn_enemy(room, Vector2(240, 0), tough)
	var third := spawn_enemy(room, Vector2(420, 0), tough)
	var far := spawn_enemy(room, Vector2(-900, 0), tough)
	await wait_frames(1)
	player.get_node("Shockwave")._pulse()
	check_eq(near.health, 990.0, "shockwave hit")
	check_eq(second.health, 992.0, "first lightning jump")
	check_eq(third.health, 992.0, "second lightning jump")
	check_eq(far.health, 1000.0, "lightning can't jump that far")


func test_blazing_trail_leaves_fire_that_burns() -> void:
	var room := await start_quiet_room()
	var player: Player = room.get_node("Player")
	player.add_boon(_boon("blazing_trail"))
	Input.action_press("move_right")
	await wait_seconds(0.5)
	Input.action_release("move_right")
	check(tree.get_nodes_in_group("fire_patches").size() >= 1, "walking should leave fire")
	var patch: FirePatch = tree.get_nodes_in_group("fire_patches")[0]
	var enemy := spawn_enemy(room, patch.global_position - player.global_position, tough_enemy_data())
	enemy.target = null # stand still in the fire
	await wait_seconds(0.5)
	check(enemy.health < 1000.0, "enemy in the fire should take damage")


func test_warriors_fury_below_half_health() -> void:
	var room := await start_quiet_room()
	var player: Player = room.get_node("Player")
	var shockwave: Shockwave = player.get_node("Shockwave")
	player.add_boon(_boon("warriors_fury"))
	check_eq(shockwave.fury_multiplier(), 1.0, "no bonus at full health")
	player.health = 30
	check_eq(shockwave.fury_multiplier(), 1.5, "bonus below half health")


func test_passive_boons() -> void:
	var room := await start_quiet_room()
	var player: Player = room.get_node("Player")
	var speed := player.character.move_speed
	player.add_boon(_boon("gale_step"))
	check_eq(player.character.move_speed, speed + 40.0, "Gale Step speed")
	player.add_boon(_boon("lunar_veil"))
	check_eq(player.invulnerable_time(), Player.INVULNERABLE_TIME + 0.5, "Lunar Veil safety window")
	player.add_boon(_boon("cleansing_rain"))
	player.health = 50
	for i in 10:
		player.register_kill()
	check_eq(player.health, 55, "Cleansing Rain heal after 10 kills")


func test_boons_carry_to_next_room() -> void:
	var room := await start_quiet_room()
	var player: Player = room.get_node("Player")
	player.add_boon(_boon("sunfire_stomp"))
	RunState.store_player(player)
	var fresh: Player = load("res://scenes/player/player.tscn").instantiate()
	room.add_child(fresh)
	RunState.restore_player(fresh)
	check_eq(fresh.boons.size(), 1, "boon count in the next room")
	fresh.queue_free()


## Find a boon by effect across all deities.
func _boon(effect: String) -> BoonData:
	for key in DEITIES:
		for boon: BoonData in load("res://data/deities/%s.tres" % key).boons:
			if boon.effect == effect:
				return boon
	return null
