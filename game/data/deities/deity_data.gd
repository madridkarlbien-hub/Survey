# Author: Karl Bien Madrid
class_name DeityData
extends Resource
## A Filipino deity who offers boons. Boon doors and the boon menu use the color.

@export var display_name: String = ""
@export var domain: String = ""
@export var color: Color = Color.WHITE
@export var boons: Array[BoonData] = []
