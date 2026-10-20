# Author: Karl Bien Madrid
class_name Player
extends CharacterBody2D
## The playable creature. Moves in 8 directions; stats come from `character`.
## Collects XP, levels up, and takes upgrades.

signal died
signal leveled_up(new_level: int)

const BODY_RADIUS := 16.0
## Seconds of safety after being hit, so a crowd can't drain health instantly.
const INVULNERABLE_TIME := 0.5
## Upgrades can never make the attack faster than this.
const MIN_ATTACK_COOLDOWN := 0.3

@export var character: CharacterData

var facing := Vector2.RIGHT
var health: int
var level := 1
var xp := 0

var _invulnerable_left := 0.0

@onready var _hurtbox: Area2D = $Hurtbox


func _ready() -> void:
	# Work on a copy, so upgrades during a run never change the saved .tres file.
	character = character.duplicate()
	health = character.max_health


func _physics_process(delta: float) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input * character.move_speed
	if input != Vector2.ZERO:
		facing = input.normalized()
		queue_redraw()
	move_and_slide()

	_invulnerable_left = maxf(_invulnerable_left - delta, 0.0)
	modulate.a = 0.4 if _invulnerable_left > 0.0 else 1.0
	if _invulnerable_left == 0.0:
		_check_contact_damage()


func take_damage(amount: int) -> void:
	if health <= 0:
		return
	health = maxi(health - amount, 0)
	_invulnerable_left = INVULNERABLE_TIME
	if health == 0:
		died.emit()


func heal(amount: int) -> void:
	if health > 0:
		health = mini(health + amount, character.max_health)


func add_xp(amount: int) -> void:
	xp += amount
	while xp >= xp_to_next_level():
		xp -= xp_to_next_level()
		level += 1
		leveled_up.emit(level)


## XP needed to go from the current level to the next: 5, 8, 11, 14...
func xp_to_next_level() -> int:
	return 5 + (level - 1) * 3


func apply_upgrade(upgrade: UpgradeData) -> void:
	var current: Variant = character.get(upgrade.stat)
	character.set(upgrade.stat, current + type_convert(upgrade.amount, typeof(current)))
	character.attack_cooldown = maxf(character.attack_cooldown, MIN_ATTACK_COOLDOWN)
	if upgrade.stat == "max_health":
		health = mini(health + int(upgrade.amount), character.max_health)


func _check_contact_damage() -> void:
	# Take one hit from the strongest enemy touching us.
	var damage := 0
	for body in _hurtbox.get_overlapping_bodies():
		if body is Enemy:
			damage = maxi(damage, body.data.contact_damage)
	if damage > 0:
		take_damage(damage)


func _draw() -> void:
	# Placeholder art: a colored circle with a line showing which way it faces.
	draw_circle(Vector2.ZERO, BODY_RADIUS, character.placeholder_color)
	draw_line(Vector2.ZERO, facing * (BODY_RADIUS + 6.0), Color.WHITE, 3.0)
