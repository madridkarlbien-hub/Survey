# Author: Karl Bien Madrid
class_name RunData
extends Resource
## The shape of one run: which rooms can appear, how many before the boss,
## and which rewards the doors can offer.

@export var room_pool: Array[RoomData] = []
@export var rooms_before_boss: int = 6
@export var boss_room: RoomData
@export var reward_pool: Array[RewardData] = []
## Each room deeper adds this much to enemy counts (0.2 = +20% per room).
@export var difficulty_per_room: float = 0.2
@export var min_doors: int = 2
@export var max_doors: int = 3
