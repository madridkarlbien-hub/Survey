# Author: Karl Bien Madrid
class_name RunGate
extends Area2D
## The gate out of the realm of the gods. Walk into it to start a run.

signal entered

const SIZE := Vector2(160, 72)
## Short delay so the gate can't trigger the instant the hub loads.
const ARM_TIME := 0.5
const COLOR := Color(1.0, 0.85, 0.4)

var _arm_left := ARM_TIME
var _used := false


func _physics_process(delta: float) -> void:
	_arm_left -= delta
	if _arm_left > 0.0 or _used:
		return
	for body in get_overlapping_bodies():
		if body is Player:
			_used = true
			entered.emit()
			return


func _draw() -> void:
	# Placeholder art: a dark archway with a golden frame.
	var rect := Rect2(-SIZE / 2.0, SIZE)
	draw_rect(rect, Color(0.05, 0.03, 0.08))
	draw_rect(rect, COLOR, false, 5.0)
