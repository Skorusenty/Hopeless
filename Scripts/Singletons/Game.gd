extends Node3D

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("Exit"):
		get_tree().quit()
