# Author: Karl Bien Madrid
class_name LevelUpMenu
extends CanvasLayer
## Pauses the game and offers a choice: upgrades on level-up or an Upgrade
## reward, or a deity's boons on a Boon reward. Picks queue up if several
## happen at once. Choose with the mouse, arrow keys + Enter, a gamepad, or 1-3.

const CHOICE_COUNT := 3
const UPGRADE_TITLE_COLOR := Color(1, 0.85, 0.4)

@export var upgrade_pool: UpgradePool

## UpgradeData or BoonData items currently on offer.
var choices: Array[Resource] = []

var _player: Player
## Picks still waiting. Each is {"title": String, "deity": DeityData or null}.
var _queue: Array[Dictionary] = []

@onready var _title: Label = %Title
@onready var _choice_list: VBoxContainer = %Choices


func _ready() -> void:
	hide()


func connect_player(player: Player) -> void:
	_player = player
	_player.leveled_up.connect(_on_player_leveled_up)


## A free upgrade pick, e.g. from an Upgrade room reward.
func offer_upgrade() -> void:
	_queue_pick("Reward! Choose an upgrade", null)


## A boon pick from this deity. Falls back to an upgrade if you own all its boons.
func offer_boon(deity: DeityData) -> void:
	if _unowned_boons(deity).is_empty():
		offer_upgrade()
	else:
		_queue_pick("%s, deity of %s, offers a blessing" % [deity.display_name, deity.domain.to_lower()], deity)


func choose(index: int) -> void:
	var choice := choices[index]
	if choice is BoonData:
		_player.add_boon(choice)
	else:
		_player.apply_upgrade(choice)
	_queue.pop_front()
	if _queue.is_empty():
		hide()
		get_tree().paused = false
	else:
		_open()


func _on_player_leveled_up(_new_level: int) -> void:
	_queue_pick("Level up! Choose an upgrade", null)


func _queue_pick(title: String, deity: DeityData) -> void:
	_queue.append({"title": title, "deity": deity})
	if not visible:
		_open()


func _open() -> void:
	get_tree().paused = true
	var pick: Dictionary = _queue[0]
	var deity: DeityData = pick.deity
	_title.text = pick.title
	if _queue.size() > 1:
		_title.text += " (%d more after this)" % (_queue.size() - 1)
	_title.add_theme_color_override("font_color", deity.color if deity else UPGRADE_TITLE_COLOR)

	choices.clear()
	if deity:
		choices.append_array(_unowned_boons(deity))
	else:
		choices.append_array(upgrade_pool.upgrades)
	choices.shuffle()
	choices.resize(mini(CHOICE_COUNT, choices.size()))

	for old_button in _choice_list.get_children():
		_choice_list.remove_child(old_button)
		old_button.queue_free()
	for i in choices.size():
		var button := Button.new()
		button.text = "%d.  %s  -  %s" % [i + 1, choices[i].display_name, choices[i].description]
		button.custom_minimum_size = Vector2(640, 64)
		button.add_theme_font_size_override("font_size", 22)
		button.pressed.connect(choose.bind(i))
		_choice_list.add_child(button)
	show()
	_choice_list.get_child(0).grab_focus()


func _unowned_boons(deity: DeityData) -> Array[BoonData]:
	return deity.boons.filter(func(boon: BoonData) -> bool: return not boon in _player.boons)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	var key := event as InputEventKey
	if key and key.pressed and not key.echo:
		var index := key.keycode - KEY_1
		if index >= 0 and index < choices.size():
			get_viewport().set_input_as_handled()
			choose(index)
