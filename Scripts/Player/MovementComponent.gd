class_name MovementComponent extends Node3D

@export_category("References")
@export var camera_component: CameraComponent
@export var player: PlayerManager
@export var stand_check: RayCast3D
@export var standing_hitbox: CollisionShape3D
@export var crouching_hitbox: CollisionShape3D
@export var head: CameraComponent
@export var eyes: Node3D
@export var cam: Camera3D

@export_category("Movement")
@export var walk_speed: float = 5.0
@export var sprint_speed: float = 7.0
@export var crouch_speed: float = 3.5
@export var jump_velocity: float = 5.0
@export var gravity: float = -16.0
@export var g_accel: float = 0.3
@export var a_accel: float = 0.1

var input_dir: Vector2
var direction: Vector3
var moving: bool
var grounded: bool
var speed: float
var current_state: PlayerEnums.playerState = PlayerEnums.playerState.IDLE_STAND

func updatePlayerState() -> void:
	moving = (input_dir != Vector2.ZERO)

	if player.movement_component.current_state == PlayerEnums.playerState.HOLDING:
		update_player_speed(current_state)
		update_player_collision(current_state)

	if !grounded:
		current_state = PlayerEnums.playerState.AIRBONE
	else:
		if Input.is_action_pressed("Crouch"):
			if !moving:
				current_state = PlayerEnums.playerState.IDLE_CROUCH
			else:
				current_state = PlayerEnums.playerState.CROUCH
		elif !stand_check.is_colliding():
			if !moving:
				current_state = PlayerEnums.playerState.IDLE_STAND
			elif Input.is_action_pressed("Sprint") and Input.is_action_pressed("Forward"):
				current_state = PlayerEnums.playerState.SPRINT
			else:
				current_state = PlayerEnums.playerState.WALK

	update_player_speed(current_state)
	update_player_collision(current_state)
	
func update_player_speed(_current_state: PlayerEnums.playerState) -> void:
	match _current_state:
		PlayerEnums.playerState.CROUCH, PlayerEnums.playerState.IDLE_CROUCH:
			speed = crouch_speed
		PlayerEnums.playerState.SPRINT:
			speed = sprint_speed
		PlayerEnums.playerState.HOLDING:
			speed = walk_speed * 0.75
		_:
			speed = walk_speed
	
func update_player_collision(_current_state: PlayerEnums.playerState) -> void:
	if _current_state == PlayerEnums.playerState.CROUCH or _current_state == PlayerEnums.playerState.IDLE_CROUCH:
		standing_hitbox.disabled = true
		crouching_hitbox.disabled = false
	else:
		standing_hitbox.disabled = false
		crouching_hitbox.disabled = true
		
func get_moving() -> bool:
	return moving
	
# Jump action
func performJump() -> void:
	player.velocity.y = jump_velocity
	
# Gravity action
func handleGravity(delta) -> void:
	if !grounded:
		player.velocity.y += gravity * delta
		
# Velocity math
func handleMovement() -> void:
	var accel: float = g_accel if grounded else a_accel
	var trueDirection = handleInput()
	if trueDirection:
		player.velocity.x = lerp(player.velocity.x, trueDirection.x * speed, accel)
		player.velocity.z = lerp(player.velocity.z, trueDirection.z * speed, accel)
	else:
		player.velocity.x = lerp(player.velocity.x, 0.0, accel)
		player.velocity.z = lerp(player.velocity.z, 0.0, accel)
	player.move_and_slide()
	
# Player input gather
func handleInput() -> Vector3:
	input_dir = player.inputGather()
	direction = (transform.basis * camera_component.get_movement_direction(input_dir))
	if direction == Vector3.ZERO:
		return Vector3.ZERO
	return direction.normalized()
	
func _physics_process(delta: float) -> void:
	grounded = player.is_on_floor()
	updatePlayerState()
	
	# Gravity activation
	handleGravity(delta)
	
	# Jump activation
	if Input.is_action_just_pressed("Jump") and grounded:
		performJump()
	
	# Player velocity math
	handleMovement()

	
