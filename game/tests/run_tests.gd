# Author: Karl Bien Madrid
extends SceneTree
## Runs every test method in tests/test_*.gd and prints PASS/FAIL for each.
## Exits with code 1 if any test fails. Start it with tools/run_tests.sh.

const TEST_DIR := "res://tests/"


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	seed(12345)
	var passed := 0
	var failed: Array[String] = []
	for file in DirAccess.get_files_at(TEST_DIR):
		if not (file.begins_with("test_") and file.ends_with(".gd")):
			continue
		var script: GDScript = load(TEST_DIR + file)
		var seen := {}
		for method in script.get_script_method_list():
			var test_name: String = method.name
			if not test_name.begins_with("test_") or seen.has(test_name):
				continue
			seen[test_name] = true
			var test: TestCase = script.new()
			test.tree = self
			await test.call(test_name)
			await test.cleanup()
			var label := "%s > %s" % [file.get_basename(), test_name]
			if test.failures.is_empty():
				passed += 1
				print("  PASS  ", label)
			else:
				failed.append(label)
				print("  FAIL  ", label)
				for failure in test.failures:
					print("          - ", failure)
	print("\n%d passed, %d failed" % [passed, failed.size()])
	quit(1 if failed.size() > 0 else 0)
