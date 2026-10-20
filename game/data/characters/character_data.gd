# Author: Karl Bien Madrid
class_name CharacterData
extends Resource
## Stats and info for one playable folklore creature.
## Make a new .tres file from this to add a character - no new code needed.
## Level-up upgrades change these stats by name (see UpgradeData).

@export var display_name: String = ""
@export_multiline var description: String = ""

@export_group("Survival")
@export var max_health: int = 100
@export var move_speed: float = 220.0
## How close XP orbs must be before they fly to you.
@export var pickup_radius: float = 80.0

@export_group("Attack")
@export var attack_damage: float = 10.0
@export var attack_radius: float = 110.0
## Seconds between attacks.
@export var attack_cooldown: float = 1.5
## How hard enemies are pushed away when hit.
@export var attack_knockback: float = 250.0

@export_group("Placeholder art")
## Body color until the real sprite is ready.
@export var placeholder_color: Color = Color.WHITE
