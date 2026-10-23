# Author: Karl Bien Madrid
class_name BakunawaBoss
extends Enemy
## The first boss: Bakunawa, the corrupted moon-eating sea serpent.
## Takes turns between three attacks, with a pause between each:
##   1. Bite: rears back (warning line), then lunges.
##   2. Moonfire: bursts of fireballs in a ring.
##   3. Summon: calls corrupted Tyanak to its side.
## Below half health it's enraged: shorter pauses, bigger and more bursts.
## Placeholder art: a segmented serpent body that trails behind the head.

const ATTACK_PAUSE := 1.8
const ENRAGED_PAUSE_SCALE := 0.6
const BITE_WINDUP := 0.8
const BITE_TIME := 0.55
const BITE_SPEED := 620.0
const RING_COUNT := 12
const ENRAGED_RING_COUNT := 18
const RING_GAP := 0.45
const SUMMON_COUNT := 5
const SUMMON_DISTANCE := 90.0
const MINION: EnemyData = preload("res://data/enemies/evil_tyanak.tres")
const SEGMENTS := 14
const SEGMENT_SPACING := 24.0
const SCALE_COLOR := Color(0.12, 0.16, 0.3)
const CRACK_COLOR := Color(0.9, 0.15, 0.25)

enum Move { SWIM, BITE_WINDUP, BITE, MOONFIRE }

var attacks_done := 0

var _move := Move.SWIM
var _move_left := ATTACK_PAUSE
var _bursts_left := 0
var _segments: Array[Vector2] = []


func is_enraged() -> bool:
	return health < data.max_health / 2.0


func _think(delta: float) -> Vector2:
	var dir := global_position.direction_to(target.global_position)
	_move_left -= delta
	match _move:
		Move.BITE_WINDUP:
			if _move_left <= 0.0:
				_move = Move.BITE
				_move_left = BITE_TIME
			return Vector2.ZERO
		Move.BITE:
			if _move_left <= 0.0:
				_swim()
			return _action_dir * BITE_SPEED
		Move.MOONFIRE:
			if _move_left <= 0.0:
				_fire_ring()
				_bursts_left -= 1
				if _bursts_left <= 0:
					_swim()
				else:
					_move_left = RING_GAP
			return Vector2.ZERO
	if _move_left <= 0.0:
		_start_attack(dir)
	return dir * data.move_speed * speed_factor()


func _start_attack(dir: Vector2) -> void:
	match attacks_done % 3:
		0:
			_move = Move.BITE_WINDUP
			_move_left = BITE_WINDUP
			_action_dir = dir
		1:
			_move = Move.MOONFIRE
			_bursts_left = 3 if is_enraged() else 2
			_move_left = 0.3
		2:
			for i in SUMMON_COUNT:
				_spawn_child(MINION, Vector2.RIGHT.rotated(TAU * i / SUMMON_COUNT) * SUMMON_DISTANCE)
			_swim()
	attacks_done += 1


func _swim() -> void:
	_move = Move.SWIM
	_move_left = ATTACK_PAUSE * (ENRAGED_PAUSE_SCALE if is_enraged() else 1.0)


func _fire_ring() -> void:
	var count := ENRAGED_RING_COUNT if is_enraged() else RING_COUNT
	var offset := randf() * TAU
	for i in count:
		_shoot(Vector2.RIGHT.rotated(offset + TAU * i / count))


func _after_move() -> void:
	# The body follows the head's path.
	if _segments.is_empty() or _segments[0].distance_to(global_position) >= SEGMENT_SPACING:
		_segments.push_front(global_position)
		if _segments.size() > SEGMENTS:
			_segments.pop_back()
	queue_redraw()


func _draw() -> void:
	# Body from tail to head, getting thicker toward the head.
	for i in range(_segments.size() - 1, 0, -1):
		var size := data.radius * lerpf(0.9, 0.35, float(i) / SEGMENTS)
		var point := to_local(_segments[i])
		draw_circle(point, size, SCALE_COLOR)
		draw_arc(point, size, 0.0, TAU, 20, CRACK_COLOR, 2.0)
	var head_color := Color.WHITE if _flash_left > 0.0 else SCALE_COLOR.lightened(0.15)
	draw_circle(Vector2.ZERO, data.radius, head_color)
	draw_arc(Vector2.ZERO, data.radius, 0.0, TAU, 32, CRACK_COLOR, 3.0)
	# Glowing eyes look where it's heading.
	var facing := global_position.direction_to(target.global_position) if is_instance_valid(target) else Vector2.RIGHT
	for side in [-1.0, 1.0]:
		draw_circle(facing * data.radius * 0.45 + facing.orthogonal() * side * data.radius * 0.4, 5.0, CRACK_COLOR)
	if _burn_left > 0.0:
		draw_arc(Vector2.ZERO, data.radius + 3.0, 0.0, TAU, 32, BURN_COLOR, 2.0)
	if _move == Move.BITE_WINDUP:
		draw_arc(Vector2.ZERO, data.radius + 8.0, 0.0, TAU, 32, WARNING_COLOR, 4.0)
		draw_line(Vector2.ZERO, _action_dir * 260.0, Color(WARNING_COLOR, 0.6), 6.0)
	elif _move == Move.MOONFIRE:
		draw_arc(Vector2.ZERO, data.radius + 8.0, 0.0, TAU, 32, Color(data.projectile_color, 0.8), 4.0)
	var bar := Rect2(-data.radius, -data.radius - 18.0, data.radius * 2.0, 7.0)
	draw_rect(bar, Color(0, 0, 0, 0.6))
	bar.size.x *= maxf(health, 0.0) / data.max_health
	draw_rect(bar, CRACK_COLOR)
