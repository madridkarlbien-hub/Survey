# Author: Karl Bien Madrid
extends Node2D
## A walled arena for testing. The floor and walls are built from `room_size`.
## Starts the waves, shows the HUD and level-up menu, and restarts the run when the player dies.

const RESTART_DELAY := 2.0

@export var room_size := Vector2(3200, 2400)
@export var wall_thickness := 32.0
@export var grid_spacing := 64.0
@export var floor_color := Color("2e2a24")
@export var grid_color := Color("3a352d")
@export var wall_color := Color("6b5640")

var _wall_rects: Array[Rect2] = []
var _time_survived := 0.0

@onready var _player: Player = $Player
@onready var _spawner: WaveSpawner = $WaveSpawner
@onready var _xp_bar: ProgressBar = $HUD/XpBar
@onready var _stats_label: Label = $HUD/Stats
@onready var _defeated_label: Label = $HUD/Defeated
@onready var _level_up_menu: LevelUpMenu = $LevelUpMenu


func _ready() -> void:
	var half := room_size / 2.0
	var t := wall_thickness
	_add_wall(Rect2(-half.x - t, -half.y - t, room_size.x + t * 2, t)) # top
	_add_wall(Rect2(-half.x - t, half.y, room_size.x + t * 2, t)) # bottom
	_add_wall(Rect2(-half.x - t, -half.y, t, room_size.y)) # left
	_add_wall(Rect2(half.x, -half.y, t, room_size.y)) # right
	queue_redraw()

	_player.died.connect(_on_player_died)
	_level_up_menu.connect_player(_player)
	_spawner.start(_player, Rect2(-half, room_size))


func _process(delta: float) -> void:
	if _player.health > 0:
		_time_survived += delta
	var seconds := int(_time_survived)
	_xp_bar.max_value = _player.xp_to_next_level()
	_xp_bar.value = _player.xp
	_stats_label.text = "Lv %d    HP %d/%d    Wave %d    Time %d:%02d" % [
		_player.level, _player.health, _player.character.max_health,
		_spawner.wave_number, seconds / 60, seconds % 60,
	]


func _on_player_died() -> void:
	_player.set_physics_process(false)
	_spawner.stop()
	_defeated_label.show()
	await get_tree().create_timer(RESTART_DELAY).timeout
	get_tree().reload_current_scene()


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
