# Author: Karl Bien Madrid
extends TestCase
## Checks that every data file loads and makes sense.


func test_all_data_files_load() -> void:
	var paths := _find_files("res://data", ".tres")
	check(paths.size() > 0, "no data files found")
	for path in paths:
		check(load(path) != null, "could not load " + path)


func test_upgrades_point_at_real_stats() -> void:
	var stats := CharacterData.new()
	var pool: UpgradePool = load("res://data/upgrades/basic_upgrades.tres")
	check(pool.upgrades.size() >= 3, "the upgrade pool needs at least 3 upgrades")
	for upgrade in pool.upgrades:
		check(upgrade.stat in stats, "%s changes unknown stat '%s'" % [upgrade.display_name, upgrade.stat])
		check(upgrade.amount != 0.0, "%s does nothing (amount is 0)" % upgrade.display_name)


func test_run_is_valid() -> void:
	var run: RunData = load("res://data/runs/first_run.tres")
	check(run.room_pool.size() >= 2, "need at least 2 rooms so rooms don't repeat back to back")
	check(run.boss_room != null, "no boss room")
	check(run.reward_pool.size() >= run.max_doors, "not enough rewards to fill every door")
	check(run.min_doors >= 1 and run.min_doors <= run.max_doors, "door counts don't make sense")


func test_rooms_are_valid() -> void:
	for path in _find_files("res://data/rooms", ".tres"):
		var room: RoomData = load(path)
		var waves := room.wave_set.waves if room.wave_set else ([] as Array[WaveData])
		check(waves.size() > 0, "%s has no waves" % path)
		for i in waves.size():
			check(waves[i].enemy != null, "%s wave %d has no enemy" % [path, i + 1])
			check(waves[i].enemy_count > 0, "%s wave %d has no enemies" % [path, i + 1])
			check(waves[i].duration > 0.0, "%s wave %d has no duration" % [path, i + 1])
		check(room.room_size.x >= 1600 and room.room_size.y >= 1000,
				"%s is too small for enemies to spawn off-screen" % path)
		if room.clear_mode == RoomData.ClearMode.SURVIVE:
			check(room.survive_time > 0.0, "%s has no survive time" % path)


func _find_files(folder: String, extension: String) -> Array[String]:
	var found: Array[String] = []
	for file in DirAccess.get_files_at(folder):
		if file.ends_with(extension):
			found.append(folder.path_join(file))
	for sub in DirAccess.get_directories_at(folder):
		found.append_array(_find_files(folder.path_join(sub), extension))
	return found
