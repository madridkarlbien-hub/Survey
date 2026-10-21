# Author: Karl Bien Madrid
extends SceneTree
## Starts the screenshot bot (tools/screenshot_bot.gd). Run tools/take_screenshots.sh.
## The bot is loaded one frame late on purpose: game scripts use autoloads such
## as SaveData, which don't exist yet while a -s script is first compiled.


func _initialize() -> void:
	_start_bot.call_deferred()


func _start_bot() -> void:
	var bot_script: GDScript = load("res://tools/screenshot_bot.gd")
	if bot_script == null or not bot_script.can_instantiate():
		push_error("The screenshot bot could not be loaded (see errors above).")
		quit(1)
		return
	root.add_child(bot_script.new())
