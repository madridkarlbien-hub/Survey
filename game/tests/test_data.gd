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


func test_waves_are_valid() -> void:
	var wave_set: WaveSet = load("res://data/waves/test_waves.tres")
	check(wave_set.waves.size() > 0, "no waves defined")
	for i in wave_set.waves.size():
		var wave := wave_set.waves[i]
		check(wave.enemy != null, "wave %d has no enemy" % (i + 1))
		check(wave.enemy_count > 0, "wave %d has no enemies to spawn" % (i + 1))
		check(wave.duration > 0.0, "wave %d has no duration" % (i + 1))


func _find_files(folder: String, extension: String) -> Array[String]:
	var found: Array[String] = []
	for file in DirAccess.get_files_at(folder):
		if file.ends_with(extension):
			found.append(folder.path_join(file))
	for sub in DirAccess.get_directories_at(folder):
		found.append_array(_find_files(folder.path_join(sub), extension))
	return found
