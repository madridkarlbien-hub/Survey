# Author: Karl Bien Madrid
class_name RewardData
extends Resource
## A room reward. Shown on a door; granted when the next room is cleared.

enum Kind {
	UPGRADE, ## A free pick from the upgrade menu.
	HEAL, ## Restore `amount` HP.
	BONUS_XP, ## Gain `amount` XP.
}

@export var display_name: String = ""
@export_multiline var description: String = ""
@export var kind: Kind = Kind.UPGRADE
@export var amount: float = 0.0
## Door color until real door art exists.
@export var color: Color = Color.WHITE
