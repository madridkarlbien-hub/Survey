# Author: Karl Bien Madrid
class_name ShrineMenu
extends CanvasLayer
## Bathala's shrine: spend Diwa on permanent upgrades. Pauses the hub while open.
## Choose with the mouse, arrow keys + Enter, or a gamepad; Esc closes.

@onready var _diwa_label: Label = %DiwaLabel
@onready var _list: VBoxContainer = %Upgrades
@onready var _leave_button: Button = %Leave


func _ready() -> void:
	hide()
	_leave_button.pressed.connect(close)


func open() -> void:
	get_tree().paused = true
	show()
	_refresh(0)


func close() -> void:
	hide()
	get_tree().paused = false


## Buy the next level of the upgrade at `index` in the shrine list.
func buy(index: int) -> bool:
	var bought: bool = SaveData.buy(SaveData.SHRINE.upgrades[index])
	_refresh(index)
	return bought


func _refresh(focus_index: int) -> void:
	_diwa_label.text = "Diwa: %d" % SaveData.diwa
	for old_button in _list.get_children():
		_list.remove_child(old_button)
		old_button.queue_free()
	var upgrades: Array[MetaUpgradeData] = SaveData.SHRINE.upgrades
	for i in upgrades.size():
		var upgrade := upgrades[i]
		var level: int = SaveData.level_of(upgrade.effect)
		var cost: int = SaveData.next_cost(upgrade)
		var price := "MAX" if cost < 0 else "%d Diwa" % cost
		var button := Button.new()
		button.text = "%s   Lv %d/%d   %s   [%s]" % [
			upgrade.display_name, level, upgrade.max_level(), upgrade.description, price]
		button.disabled = not SaveData.can_buy(upgrade)
		button.custom_minimum_size = Vector2(900, 52)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.add_theme_font_size_override("font_size", 19)
		button.pressed.connect(buy.bind(i))
		_list.add_child(button)
	var focus: Control = _list.get_child(focus_index)
	if focus.disabled:
		focus = _leave_button
	focus.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()
