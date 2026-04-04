class_name PlayerManager extends CharacterBody3D

@export_category("References")
@export var camera_component: CameraComponent
@export var movement_component: MovementComponent
@export var interaction_component: InteractionComponent
@export var pickup_component: PickupComponent


var is_local: bool = false

func _enter_tree() -> void:
	set_multiplayer_authority(1)

func _ready() -> void:
	await get_tree().physics_frame
	await get_tree().process_frame
	is_local = (name.to_int() == multiplayer.get_unique_id())
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	if is_local:
		camera_component.cam.current = true
		camera_component.set_process_unhandled_input(true)
	else:
		camera_component.set_process_unhandled_input(false)
		camera_component.cam.current = false
	
	print("Player: ", name, " | local: ", is_local, " | my_id: ", multiplayer.get_unique_id())

func _process(delta: float) -> void:
	if not is_local:
		return
	camera_component.update_camera(delta)
	
func input_gather() -> Vector2:
	var input = Input.get_vector("Forward", "Backward", "Left", "Right")
	if input:
		return input
	else:
		return Vector2.ZERO

func get_pickup_comp() -> PickupComponent:
	return pickup_component
