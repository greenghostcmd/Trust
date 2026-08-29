extends CharacterBody2D
class_name TrustPlayer

const DEFAULT_SPEED := 110.0

@export var speed: float = DEFAULT_SPEED
var rule_manager: DeceptionManager
var movement_enabled: bool = true

func _physics_process(_delta: float) -> void:
	if not movement_enabled:
		velocity = Vector2.ZERO
		return
	var direction: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if rule_manager != null:
		direction = rule_manager.transform_movement(direction)
	velocity = direction * speed
	move_and_slide()
