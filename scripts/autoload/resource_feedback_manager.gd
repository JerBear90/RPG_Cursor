extends Node
## HUD resource-gain notifications — driven by actual inventory grants.

signal resources_obtained(rewards: Dictionary)


func notify_granted(rewards: Dictionary) -> void:
	if rewards.is_empty():
		return
	resources_obtained.emit(rewards)
