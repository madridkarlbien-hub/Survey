# Author: Karl Bien Madrid
class_name BoonData
extends Resource
## A blessing from a deity. `effect` picks what it does (the code for each effect
## lives in Shockwave, Enemy and Player); `power`, `duration` and `count` tune it.
## Boons stack: every boon you own is active at once.

@export var display_name: String = ""
@export_multiline var description: String = ""
@export_enum("sunfire_stomp", "warriors_fury", "blazing_trail", "moonlit_stomp", "lunar_veil", "crescent_echo", "tidal_stomp", "undertow", "riptide", "stormcall_stomp", "gale_step", "cleansing_rain") var effect: String = "sunfire_stomp"
## The main strength: damage per second, slow amount, pull force, heal amount...
@export var power: float = 0.0
## Seconds an effect lasts (burn, slow, fire patches).
@export var duration: float = 0.0
## A count: lightning jumps, kills per heal.
@export var count: int = 0
