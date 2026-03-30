class_name PlayerManager extends CharacterBody3D

@export_category("References")
@export var camera_component: CameraComponent
@export var movement_component: MovementComponent
@export var interaction_component: InteractionComponent
@export var pickup_component: PickupComponent

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _process(delta: float) -> void:
	camera_component.update_camera(delta)
	
func inputGather() -> Vector2:
	var input = Input.get_vector("Forward", "Backward", "Left", "Right")
	if input:
		return input
	else:
		return Vector2.ZERO
		
func _input(_event: InputEvent) -> void:
	 # CURSOR RELEASE
	if Input.is_action_pressed("Altmouse"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# GAME EXIT (FOR NOW)
	if Input.is_action_just_pressed("Exit"):
		get_tree().quit()
		
	# INTERACTIONS
	if Input.is_action_just_pressed("Interact"):
		if pickup_component.is_holding():
			pickup_component.place()
		else:
			interaction_component.activate()
			
	if pickup_component.is_holding():
		if Input.is_action_just_pressed("Throw"):
			pickup_component.begin_charge()
		if Input.is_action_just_released("Throw"):
			pickup_component.throw()
		
	if Input.is_action_just_pressed("Drop") and pickup_component.is_holding():
		pickup_component.drop()

func get_pickup_comp() -> PickupComponent:
	return pickup_component
