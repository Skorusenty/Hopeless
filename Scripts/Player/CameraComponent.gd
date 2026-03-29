class_name CameraComponent extends Node3D
@export var movement_component: MovementComponent
@export var cam: Camera3D
@export var player: PlayerManager
@export var eyes: Node3D
@export var crouch_depth: float = -0.8
@export var head_base_pos: float = 1.8
@export var base_fov: float = 90.0
@export var lerp_speed: float = 10.0
@export var sensitivity: float = 0.2
@export_category("HeadBobbing")
@export var sprint_bob_speed: float = 22.0
@export var walk_bob_speed: float = 14.0
@export var crouch_bob_speed: float = 10.0
@export var sprint_bob_amp: float = 0.2
@export var walk_bob_amp: float = 0.1
@export var crouch_bob_amp: float = 0.05
@export var current_bob_amp: float = 0.0
var head_bob_vector: Vector2 = Vector2.ZERO
var head_bob_index: float = 0.0

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		player.rotate_y(deg_to_rad(-event.relative.x * sensitivity))
		self.rotate_x(deg_to_rad(-event.relative.y * sensitivity))
		self.rotation.x = clamp(self.rotation.x, deg_to_rad(-80), deg_to_rad(80))

func get_movement_direction(input: Vector2) -> Vector3:
	var forward = self.global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized()

	var right = self.global_transform.basis.x
	right.y = 0.0
	right = right.normalized()

	return (forward * input.x + right * input.y).normalized()

func update_camera(_delta) -> void:
	if movement_component.current_state == PlayerEnums.playerState.AIRBONE:
		return
	elif movement_component.current_state == PlayerEnums.playerState.CROUCH or movement_component.current_state == PlayerEnums.playerState.IDLE_CROUCH:
		self.position.y = lerp(self.position.y, head_base_pos + crouch_depth, _delta * lerp_speed)
		cam.fov = lerp(cam.fov, base_fov * 0.95, _delta * lerp_speed)
		current_bob_amp = crouch_bob_amp
		head_bob_index += crouch_bob_speed * _delta
	elif movement_component.current_state == PlayerEnums.playerState.IDLE_STAND or movement_component.current_state == PlayerEnums.playerState.WALK:
		self.position.y = lerp(self.position.y, head_base_pos, _delta * lerp_speed)
		cam.fov = lerp(cam.fov, base_fov, _delta * lerp_speed)
		current_bob_amp = walk_bob_amp
		head_bob_index += walk_bob_speed * _delta
	elif movement_component.current_state == PlayerEnums.playerState.SPRINT:
		self.position.y = lerp(self.position.y, head_base_pos, _delta * lerp_speed)
		cam.fov = lerp(cam.fov, base_fov * 1.05, _delta * lerp_speed)
		current_bob_amp = sprint_bob_amp
		head_bob_index += sprint_bob_speed * _delta

	head_bob_vector.y = sin(head_bob_index)
	head_bob_vector.x = (sin(head_bob_index/2.0) + 0.5)

	if movement_component.get_moving():
		eyes.position.y = lerp(eyes.position.y, head_bob_vector.y * (current_bob_amp/2.0), _delta * lerp_speed)
		eyes.position.x = lerp(eyes.position.x, head_bob_vector.x * (current_bob_amp), _delta * lerp_speed)
	else:
		eyes.position.y = lerp(eyes.position.y, 0.0, _delta * lerp_speed)
		eyes.position.x = lerp(eyes.position.x, 0.0, _delta * lerp_speed)
