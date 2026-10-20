# Author: Karl Bien Madrid
class_name LevelUpMenu
extends CanvasLayer
## Pauses the game and offers random upgrades on each level-up or Upgrade reward.
## Pick with the mouse, arrow keys + Enter, a gamepad, or the number keys 1-3.

const CHOICE_COUNT := 3

@export var upgrade_pool: UpgradePool

var choices: Array[UpgradeData] = []

var _player: Player
## One title per pick still waiting, e.g. two level-ups in a row.
var _queue: Array[String] = []

@onready var _title: Label = %Title
@onready var _choice_list: VBoxContainer = %Choices


func _ready() -> void:
	hide()


func connect_player(player: Player) -> void:
	_player = player
	_player.leveled_up.connect(_on_player_leveled_up)


## A free pick, e.g. from an Upgrade room reward.
func offer_upgrade() -> void:
	_queue_pick("Reward! Choose an upgrade")


func choose(index: int) -> void:
	_player.apply_upgrade(choices[index])
	_queue.pop_front()
	if _queue.is_empty():
		hide()
		get_tree().paused = false
	else:
		_open()


func _on_player_leveled_up(_new_level: int) -> void:
	_queue_pick("Level up! Choose an upgrade")


func _queue_pick(title: String) -> void:
	_queue.append(title)
	if not visible:
		_open()


func _open() -> void:
	get_tree().paused = true
	_title.text = _queue[0]
	if _queue.size() > 1:
		_title.text += " (%d more after this)" % (_queue.size() - 1)

	choices = upgrade_pool.upgrades.duplicate()
	choices.shuffle()
	choices.resize(mini(CHOICE_COUNT, choices.size()))

	for old_button in _choice_list.get_children():
		_choice_list.remove_child(old_button)
		old_button.queue_free()
	for i in choices.size():
		var button := Button.new()
		button.text = "%d.  %s  -  %s" % [i + 1, choices[i].display_name, choices[i].description]
		button.custom_minimum_size = Vector2(560, 64)
		button.add_theme_font_size_override("font_size", 22)
		button.pressed.connect(choose.bind(i))
		_choice_list.add_child(button)
	show()
	_choice_list.get_child(0).grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	var key := event as InputEventKey
	if key and key.pressed and not key.echo:
		var index := key.keycode - KEY_1
		if index >= 0 and index < choices.size():
			get_viewport().set_input_as_handled()
			choose(index)
