# Author: Karl Bien Madrid
class_name Enemy
extends CharacterBody2D
## A basic enemy that walks straight at its target. Stats come from `data`.

var data: EnemyData
var target: Node2D
var health: int


## Call before adding the enemy to the scene.
func setup(enemy_data: EnemyData, chase_target: Node2D) -> void:
	data = enemy_data
	target = chase_target
	health = data.max_health
	var shape := CircleShape2D.new()
	shape.radius = data.radius
	$CollisionShape2D.shape = shape


func _physics_process(_delta: float) -> void:
	if not is_instance_valid(target):
		return
	velocity = global_position.direction_to(target.global_position) * data.move_speed
	move_and_slide()


func _draw() -> void:
	# Placeholder art: a dark body with a red ring so enemies read as hostile.
	draw_circle(Vector2.ZERO, data.radius, data.placeholder_color)
	draw_arc(Vector2.ZERO, data.radius, 0.0, TAU, 24, Color(0.9, 0.15, 0.2), 2.0)
