# Author: Karl Bien Madrid
extends Node
## Progress that lasts between runs and game sessions: Diwa, permanent upgrades
## bought at Bathala's shrine, and run records. Saved as JSON in the user folder.
## Always loaded (autoload), so every scene can reach it as `SaveData`.

const DEFAULT_PATH := "user://save.json"
const SHRINE: MetaUpgradePool = preload("res://data/meta/shrine_upgrades.tres")

var save_path := DEFAULT_PATH
var diwa := 0
var runs := 0
var wins := 0
## Upgrade effect name -> level bought.
var levels := {}


func _ready() -> void:
	load_game()


func reset() -> void:
	diwa = 0
	runs = 0
	wins = 0
	levels = {}


func load_game() -> void:
	reset()
	if not FileAccess.file_exists(save_path):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	if not parsed is Dictionary:
		push_warning("Save file is damaged; starting fresh: " + save_path)
		return
	diwa = int(parsed.get("diwa", 0))
	runs = int(parsed.get("runs", 0))
	wins = int(parsed.get("wins", 0))
	var saved_levels: Dictionary = parsed.get("levels", {})
	for effect in saved_levels:
		levels[effect] = int(saved_levels[effect])


func save_game() -> void:
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		push_warning("Could not write save file: " + save_path)
		return
	file.store_string(JSON.stringify({"diwa": diwa, "runs": runs, "wins": wins, "levels": levels}, "\t"))


func level_of(effect: String) -> int:
	return int(levels.get(effect, 0))


## The total bonus from an upgrade's bought levels (0 if none).
func bonus(effect: String) -> float:
	var upgrade := SHRINE.find(effect)
	return upgrade.amount_per_level * level_of(effect) if upgrade else 0.0


## Price of the next level, or -1 when the upgrade is maxed.
func next_cost(upgrade: MetaUpgradeData) -> int:
	var level := level_of(upgrade.effect)
	return -1 if level >= upgrade.max_level() else upgrade.costs[level]


func can_buy(upgrade: MetaUpgradeData) -> bool:
	var cost := next_cost(upgrade)
	return cost >= 0 and diwa >= cost


## Spend Diwa on the next level. Returns false if maxed or too expensive.
func buy(upgrade: MetaUpgradeData) -> bool:
	if not can_buy(upgrade):
		return false
	diwa -= next_cost(upgrade)
	levels[upgrade.effect] = level_of(upgrade.effect) + 1
	save_game()
	return true
