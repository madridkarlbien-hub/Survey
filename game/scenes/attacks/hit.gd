# Author: Karl Bien Madrid
class_name Hit
extends RefCounted
## Everything one attack does to an enemy: damage, push, and any boon effects.

var damage := 0.0
var push := Vector2.ZERO
## Burn (Sunfire Stomp): damage per second, for this many seconds.
var burn_dps := 0.0
var burn_time := 0.0
## Slow (Moonlit Stomp): 0.4 = 40% slower, for this many seconds.
var slow_amount := 0.0
var slow_time := 0.0
## Riptide: damage taken if this hit knocks the enemy into a wall.
var wall_damage := 0.0


func _init(hit_damage := 0.0, hit_push := Vector2.ZERO) -> void:
	damage = hit_damage
	push = hit_push
