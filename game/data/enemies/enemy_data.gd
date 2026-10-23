# Author: Karl Bien Madrid
class_name EnemyData
extends Resource
## Stats and behavior for one enemy type.
## Make a new .tres file from this to add an enemy - no new code needed
## unless it needs a brand-new behavior.

@export var display_name: String = ""
@export var max_health: int = 10
@export var move_speed: float = 110.0
@export var contact_damage: int = 5
@export var radius: float = 12.0
## XP dropped when defeated.
@export var xp_value: int = 1
## 0 = full knockback, 1 = can't be pushed at all.
@export_range(0.0, 1.0) var knockback_resistance: float = 0.0
## Draw a health bar above this enemy, and show it on the HUD (for bosses).
@export var show_health_bar: bool = false
## Chance (0-1) to also drop Diwa when defeated.
@export_range(0.0, 1.0) var diwa_chance: float = 0.08
@export var diwa_amount: int = 1

@export_group("Look")
## Sprite art. If empty, a colored circle is drawn instead.
@export var sprite: Texture2D
## How tall the sprite is drawn, in pixels.
@export var sprite_height: float = 40.0
## Which way the art faces, so it can be flipped to face where it's going.
@export var sprite_faces_right: bool = true
## Body color for the circle placeholder (and the boss's body).
@export var placeholder_color: Color = Color.WHITE
## Use a special scene instead of the normal enemy (e.g. the Bakunawa boss).
@export var custom_scene: PackedScene

@export_group("Behavior")
## chase: walk straight at you. leap: pounce from close range. charge: wind up,
## then rush in a straight line. ranged / spread / homing: keep distance and
## shoot. teleport: fade out and reappear near you. vortex: pull you in.
@export_enum("chase", "leap", "charge", "ranged", "spread", "homing", "teleport", "vortex") var behavior: String = "chase"
## How close you must be before the special move starts.
@export var attack_range: float = 0.0
## Seconds between special moves.
@export var attack_cooldown: float = 2.0
## Seconds of warning (standing still, glowing) before the move.
@export var windup_time: float = 0.4
## How long a leap, charge, fade or pull lasts.
@export var action_time: float = 0.3
## Speed during a leap or charge.
@export var action_speed: float = 0.0
## Shooters stop approaching at this distance.
@export var keep_distance: float = 0.0
## Vortex: how hard you are pulled (pixels per second).
@export var pull_strength: float = 0.0
## Spawned where this enemy dies (e.g. the Manananggal's torso).
@export var split_into: EnemyData

@export_group("Projectiles")
@export var projectile_count: int = 1
## Total angle of a fan of projectiles, in degrees.
@export var projectile_spread: float = 0.0
@export var projectile_speed: float = 200.0
@export var projectile_damage: int = 6
## How fast a projectile turns toward you (radians per second; 0 = straight).
@export var projectile_homing: float = 0.0
@export var projectile_lifetime: float = 4.0
@export var projectile_color: Color = Color(1.0, 0.5, 0.2)
