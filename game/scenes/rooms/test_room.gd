# Author: Karl Bien Madrid
extends Node2D
## A walled arena for testing. The floor and walls are built from `room_size`.

@export var room_size := Vector2(1600, 1200)
@export var wall_thickness := 32.0
@export var grid_spacing := 64.0
@export var floor_color := Color("2e2a24")
@export var grid_color := Color("3a352d")
@export var wall_color := Color("6b5640")

var _wall_rects: Array[Rect2] = []


func _ready() -> void:
	var half := room_size / 2.0
	var t := wall_thickness
	_add_wall(Rect2(-half.x - t, -half.y - t, room_size.x + t * 2, t)) # top
	_add_wall(Rect2(-half.x - t, half.y, room_size.x + t * 2, t)) # bottom
	_add_wall(Rect2(-half.x - t, -half.y, t, room_size.y)) # left
	_add_wall(Rect2(half.x, -half.y, t, room_size.y)) # right
	queue_redraw()


func _add_wall(rect: Rect2) -> void:
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	var collision := CollisionShape2D.new()
	collision.shape = shape
	var body := StaticBody2D.new()
	body.position = rect.get_center()
	body.add_child(collision)
	add_child(body)
	_wall_rects.append(rect)


func _draw() -> void:
	var half := room_size / 2.0
	draw_rect(Rect2(-half, room_size), floor_color)
	# Grid lines make movement easy to see while there is no real art yet.
	var x := -half.x
	while x <= half.x:
		draw_line(Vector2(x, -half.y), Vector2(x, half.y), grid_color)
		x += grid_spacing
	var y := -half.y
	while y <= half.y:
		draw_line(Vector2(-half.x, y), Vector2(half.x, y), grid_color)
		y += grid_spacing
	for rect in _wall_rects:
		draw_rect(rect, wall_color)
