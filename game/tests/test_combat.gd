# Author: Karl Bien Madrid
extends TestCase
## The shockwave attack, enemy death, and XP orbs.


func test_shockwave_hits_only_nearby_enemies() -> void:
	var room := await start_quiet_room()
	var near := spawn_enemy(room, Vector2(60, 0))
	var far := spawn_enemy(room, Vector2(600, 0))
	await wait_seconds(1.1) # first pulse is at 1 second
	check(not is_instance_valid(near), "nearby enemy should be defeated by the shockwave")
	check(is_instance_valid(far) and far.health == far.data.max_health, "far enemy should be untouched")


func test_defeated_enemy_gives_xp() -> void:
	var room := await start_quiet_room()
	var player: Player = room.get_node("Player")
	spawn_enemy(room, Vector2(60, 0))
	await wait_seconds(1.6)
	check_eq(player.xp, 1, "XP after the orb flies to the player")
	check_eq(tree.get_nodes_in_group("xp_orbs").size(), 0, "orb should be collected")


func test_orbs_outside_pickup_range_stay_put() -> void:
	var room := await start_quiet_room()
	var player: Player = room.get_node("Player")
	var orb: XpOrb = load("res://scenes/pickups/xp_orb.tscn").instantiate()
	orb.position = player.position + Vector2(300, 0)
	room.add_child(orb)
	await wait_seconds(0.5)
	check(is_instance_valid(orb), "orb should still exist")
	check_eq(orb.position, player.position + Vector2(300, 0), "orb position")
