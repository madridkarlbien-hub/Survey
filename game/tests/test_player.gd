# Author: Karl Bien Madrid
extends TestCase
## Player health, damage, XP and levels.


func test_starts_with_full_health() -> void:
	var player: Player = (await start_quiet_room()).get_node("Player")
	check_eq(player.health, player.character.max_health, "health at start")
	check_eq(player.level, 1, "level at start")


func test_contact_damage_has_invulnerability() -> void:
	var room := await start_quiet_room()
	var player: Player = room.get_node("Player")
	spawn_enemy(room, Vector2(10, 0))
	await wait_seconds(0.3)
	check_eq(player.health, player.character.max_health - 5, "one hit within the safety window")
	await wait_seconds(0.4)
	check_eq(player.health, player.character.max_health - 10, "second hit after the safety window")


func test_death_emits_signal() -> void:
	var room := await start_quiet_room()
	var player: Player = room.get_node("Player")
	player.died.disconnect(room._on_player_died) # don't restart the scene mid-test
	var died := [false]
	player.died.connect(func() -> void: died[0] = true)
	player.take_damage(9999)
	check_eq(player.health, 0, "health after a huge hit")
	check(died[0], "died signal was not sent")


func test_xp_levels_up() -> void:
	var player: Player = (await start_quiet_room()).get_node("Player")
	var needed := player.xp_to_next_level()
	player.add_xp(needed - 1)
	check_eq(player.level, 1, "level just below the threshold")
	player.add_xp(1)
	check_eq(player.level, 2, "level after reaching the threshold")
	check_eq(player.xp, 0, "leftover XP")
