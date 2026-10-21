# Author: Karl Bien Madrid
extends Node2D
## Kaluwalhatian, the realm of the gods. A safe place between runs: speak with
## Bathala at his shrine to buy permanent upgrades, then walk through the gate
## to start a run. Runs return here when they end.

const ARENA_SCENE := "res://scenes/rooms/arena_room.tscn"
const ROOM_SIZE := Vector2(1600, 1000)
const WALL_THICKNESS := 32.0
## How close the player must be to Bathala to open the shrine.
const TALK_DISTANCE := 120.0
const STAR_COUNT := 140
const FLOOR_COLOR := Color("1b1630")
const PATTERN_COLOR := Color(1.0, 0.85, 0.4, 0.07)
const WALL_COLOR := Color("4a3d6b")

var _wall_rects: Array[Rect2] = []
var _stars: Array[Vector2] = []

@onready var _player: Player = $Player
@onready var _bathala: DeityStatue = $Bathala
@onready var _gate: RunGate = $RunGate
@onready var _shrine_menu: ShrineMenu = $ShrineMenu
@onready var _diwa_label: Label = $HubHUD/Diwa
@onready var _record_label: Label = $HubHUD/Record
@onready var _prompt: Label = $HubHUD/Prompt


func _ready() -> void:
	RunState.end_run()
	_wall_rects = RoomWalls.build(self, ROOM_SIZE, WALL_THICKNESS)
	RoomWalls.limit_camera(_player.get_node("Camera2D"), ROOM_SIZE, WALL_THICKNESS)
	# The hub is paused while the shrine is open, so hide the prompt right away.
	_shrine_menu.visibility_changed.connect(func() -> void: _prompt.visible = false)
	# No fighting in the realm of the gods.
	var shockwave := _player.get_node("Shockwave")
	shockwave.process_mode = Node.PROCESS_MODE_DISABLED
	shockwave.hide()
	_gate.entered.connect(_on_gate_entered)
	# Fixed seed, so the stars are in the same place every visit.
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in STAR_COUNT:
		_stars.append(Vector2(rng.randf_range(-0.5, 0.5), rng.randf_range(-0.5, 0.5)) * ROOM_SIZE)
	queue_redraw()


func _process(_delta: float) -> void:
	_prompt.visible = is_near_bathala() and not _shrine_menu.visible
	_diwa_label.text = "Diwa %d" % SaveData.diwa
	_record_label.text = "Runs %d    Wins %d" % [SaveData.runs, SaveData.wins]


func is_near_bathala() -> bool:
	return _player.global_position.distance_to(_bathala.global_position) <= TALK_DISTANCE


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and _prompt.visible:
		get_viewport().set_input_as_handled()
		_shrine_menu.open()


func _on_gate_entered() -> void:
	RunState.start_run()
	get_tree().change_scene_to_file.call_deferred(ARENA_SCENE)


func _draw() -> void:
	var half := ROOM_SIZE / 2.0
	draw_rect(Rect2(-half, ROOM_SIZE), FLOOR_COLOR)
	# Placeholder art: faint golden rings around the shrine, and scattered stars.
	for ring in range(1, 8):
		draw_arc(_bathala.position, ring * 90.0, 0.0, TAU, 64, PATTERN_COLOR, 2.0)
	for star in _stars:
		draw_circle(star, 1.5, Color(1, 1, 1, 0.5))
	for rect in _wall_rects:
		draw_rect(rect, WALL_COLOR)
