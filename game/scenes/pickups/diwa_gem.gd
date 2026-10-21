# Author: Karl Bien Madrid
class_name DiwaGem
extends XpOrb
## Diwa (spirit essence), dropped by some enemies. Flies to the player like XP,
## but is kept forever, even when the run is lost. Spent at Bathala's shrine.

const COLOR := Color(0.75, 0.45, 1.0)


func _collect() -> void:
	SaveData.diwa += value
	RunState.run_diwa += value


func _draw() -> void:
	# Placeholder art: a small violet diamond.
	var points := PackedVector2Array([Vector2(0, -8), Vector2(6, 0), Vector2(0, 8), Vector2(-6, 0)])
	draw_colored_polygon(points, COLOR)
	draw_polyline(points + PackedVector2Array([points[0]]), Color(1, 0.9, 1), 1.5)
