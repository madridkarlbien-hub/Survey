# Author: Karl Bien Madrid
class_name Door
extends Area2D
## An exit that appears when a room is cleared. Shows the reward waiting in
## the next room; walk into it to go there. A null reward means the boss door.

signal entered(reward: RewardData)

const SIZE := Vector2(96, 64)
## Short delay so a door can't trigger the instant it appears under the player.
const ARM_TIME := 0.5
const BOSS_COLOR := Color(0.9, 0.2, 0.25)

var reward: RewardData

var _arm_left := ARM_TIME
var _used := false


func _ready() -> void:
	$Label.text = reward.display_name if reward else "BOSS"
	$Label.modulate = reward.color if reward else BOSS_COLOR


func _physics_process(delta: float) -> void:
	_arm_left -= delta
	if _arm_left > 0.0 or _used:
		return
	for body in get_overlapping_bodies():
		if body is Player:
			_used = true
			entered.emit(reward)
			return


func _draw() -> void:
	# Placeholder art: a dark doorway with a glowing frame in the reward's color.
	var color := reward.color if reward else BOSS_COLOR
	var rect := Rect2(-SIZE / 2.0, SIZE)
	draw_rect(rect, Color(0.05, 0.04, 0.04))
	draw_rect(rect, color, false, 4.0)
