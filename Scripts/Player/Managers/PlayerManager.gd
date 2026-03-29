class_name PlayerManager extends CharacterBody3D

@export_category("References")
@export var movement_component: MovementComponent


func get_inputs() -> Vector2:
	var input = Input.get_vector("Forward", "Backward", "Left", "Right")
	if input:
		return input
	else:
		return Vector2.ZERO
