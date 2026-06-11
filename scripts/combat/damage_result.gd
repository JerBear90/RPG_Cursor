class_name DamageResult
extends RefCounted
## Outcome of a single damage application attempt.

var accepted: bool = false
var raw_damage: float = 0.0
var final_damage: float = 0.0
var health_before: float = 0.0
var health_after: float = 0.0
var was_blocked: bool = false
var was_critical: bool = false
var killed_target: bool = false
var reject_reason: String = ""
