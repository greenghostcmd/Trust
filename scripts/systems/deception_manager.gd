extends Node
class_name DeceptionManager

signal rule_changed(rule_name: StringName, enabled: bool)

const MOVEMENT_LIE: StringName = &"movement_lie"
const OBJECTIVE_LIE: StringName = &"objective_lie"
const ENVIRONMENT_LIE: StringName = &"environment_lie"
const DOOR_LIE: StringName = &"door_lie"
const SIGN_LIE: StringName = &"sign_lie"

var rules: Dictionary = {
	MOVEMENT_LIE: false,
	OBJECTIVE_LIE: false,
	ENVIRONMENT_LIE: false,
	DOOR_LIE: false,
	SIGN_LIE: false,
}

func reset() -> void:
	for rule_name in rules:
		set_rule(StringName(rule_name), false)

func set_rule(rule_name: StringName, enabled: bool) -> void:
	if not rules.has(rule_name):
		rules[rule_name] = false
	if rules[rule_name] == enabled:
		return
	rules[rule_name] = enabled
	rule_changed.emit(rule_name, enabled)

func is_enabled(rule_name: StringName) -> bool:
	return bool(rules.get(rule_name, false))

func transform_movement(direction: Vector2) -> Vector2:
	return -direction if is_enabled(MOVEMENT_LIE) else direction
