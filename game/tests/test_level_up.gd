# Author: Karl Bien Madrid
extends TestCase
## The level-up menu and upgrades.


func test_level_up_pauses_and_offers_three_choices() -> void:
	var room := await start_quiet_room()
	var player: Player = room.get_node("Player")
	var menu: LevelUpMenu = room.get_node("LevelUpMenu")
	player.add_xp(player.xp_to_next_level())
	check(tree.paused, "game should pause on level-up")
	check(menu.visible, "menu should be visible")
	check_eq(menu.choices.size(), 3, "number of choices")
	var names := {}
	for upgrade in menu.choices:
		names[upgrade.display_name] = true
	check_eq(names.size(), 3, "choices should all be different")


func test_choosing_applies_upgrade_and_resumes() -> void:
	var room := await start_quiet_room()
	var player: Player = room.get_node("Player")
	var menu: LevelUpMenu = room.get_node("LevelUpMenu")
	player.add_xp(player.xp_to_next_level())
	var upgrade := menu.choices[0]
	var before: float = player.character.get(upgrade.stat)
	menu.choose(0)
	var after: float = player.character.get(upgrade.stat)
	check(not is_equal_approx(after, before), "%s should change %s" % [upgrade.display_name, upgrade.stat])
	check(not tree.paused, "game should resume")
	check(not menu.visible, "menu should close")


func test_several_level_ups_queue_up() -> void:
	var room := await start_quiet_room()
	var player: Player = room.get_node("Player")
	var menu: LevelUpMenu = room.get_node("LevelUpMenu")
	player.add_xp(100)
	var levels_gained := player.level - 1
	check(levels_gained >= 2, "100 XP should give several levels")
	for i in levels_gained:
		check(menu.visible, "menu should stay open for level-up %d" % (i + 1))
		menu.choose(0)
	check(not menu.visible and not tree.paused, "menu should close after the last choice")


func test_upgrades_do_not_change_saved_character() -> void:
	var room := await start_quiet_room()
	var player: Player = room.get_node("Player")
	var damage_upgrade := UpgradeData.new()
	damage_upgrade.stat = "attack_damage"
	damage_upgrade.amount = 50.0
	player.apply_upgrade(damage_upgrade)
	var saved: CharacterData = load("res://data/characters/tikbalang.tres")
	check_eq(player.character.attack_damage, saved.attack_damage + 50.0, "upgraded damage in the run")
	check_eq(saved.attack_damage, 10.0, "saved Tikbalang file must stay unchanged")


func test_attack_cooldown_has_a_floor() -> void:
	var player: Player = (await start_quiet_room()).get_node("Player")
	var faster := UpgradeData.new()
	faster.stat = "attack_cooldown"
	faster.amount = -100.0
	player.apply_upgrade(faster)
	check_eq(player.character.attack_cooldown, Player.MIN_ATTACK_COOLDOWN, "cooldown floor")
