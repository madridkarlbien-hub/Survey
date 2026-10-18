# Author: Karl Bien Madrid
class_name WaveData
extends Resource
## One wave: which enemy, how many, and over how many seconds they arrive.

@export var enemy: EnemyData
@export var enemy_count: int = 10
@export var duration: float = 20.0
