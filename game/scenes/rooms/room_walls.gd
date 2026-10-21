# Author: Karl Bien Madrid
class_name RoomWalls
## Builds the four walls around a rectangular room centered on (0, 0).


## Adds wall bodies to `parent` and returns their rectangles (for drawing).
static func build(parent: Node2D, room_size: Vector2, thickness: float) -> Array[Rect2]:
	var half := room_size / 2.0
	var t := thickness
	var rects: Array[Rect2] = [
		Rect2(-half.x - t, -half.y - t, room_size.x + t * 2, t), # top
		Rect2(-half.x - t, half.y, room_size.x + t * 2, t), # bottom
		Rect2(-half.x - t, -half.y, t, room_size.y), # left
		Rect2(half.x, -half.y, t, room_size.y), # right
	]
	for rect in rects:
		var shape := RectangleShape2D.new()
		shape.size = rect.size
		var collision := CollisionShape2D.new()
		collision.shape = shape
		var body := StaticBody2D.new()
		body.position = rect.get_center()
		body.add_child(collision)
		parent.add_child(body)
	return rects
