# Author: Karl Bien Madrid
class_name MetaUpgradePool
extends Resource
## Every permanent upgrade on sale at Bathala's shrine, in display order.

@export var upgrades: Array[MetaUpgradeData] = []


func find(effect: String) -> MetaUpgradeData:
	for upgrade in upgrades:
		if upgrade.effect == effect:
			return upgrade
	return null
