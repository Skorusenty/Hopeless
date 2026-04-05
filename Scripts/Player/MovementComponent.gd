class_name MovementComponent extends Node3D

@export_category("References")
@export var camera_component: CameraComponent
@export var player: PlayerManager
@export var stand_check: RayCast3D
@export var standing_hitbox: CollisionShape3D
@export var crouching_hitbox: CollisionShape3D
@export var standing_mesh: MeshInstance3D
@export var crouching_mesh: MeshInstance3D
@export var head: CameraComponent
@export var eyes: Node3D
@export var cam: Camera3D
@export var sync: MultiplayerSynchronizer

@export_category("Movement")
@export var walk_speed: float = 5.0
@export var sprint_speed: float = 7.0
@export var crouch_speed: float = 3.5
@export var jump_velocity: float = 5.0
@export var gravity: float = -16.0
@export var g_accel: float = 0.3
@export var a_accel: float = 0.1

# MULTIPLAYER SYNC VARIABLES
@export var current_state: PlayerEnums.playerState = PlayerEnums.playerState.IDLE_STAND
@export var new_vel: Vector3
var input_dir: Vector2
var direction: Vector3
var moving: bool
var can_jump: bool
var can_crouch: bool
var can_sprint: bool
var grounded: bool
var speed: float


func _process(_delta: float) -> void:
	# CLIENT SIDE INPUT RPC STORAGE
	if player.is_local:
		handle_input()

func update_player_state() -> void:
	# STATE MACHINE / SERVER SIDE
	if not is_multiplayer_authority():
		return
	
	var is_moving = get_moving()
	
	if player.movement_component.current_state == PlayerEnums.playerState.HOLDING:
		update_player_speed(current_state)
		update_player_collision(current_state)

	if !grounded:
		current_state = PlayerEnums.playerState.AIRBONE
	else:
		if can_crouch and grounded:
			if !is_moving:
				current_state = PlayerEnums.playerState.IDLE_CROUCH
			else:
				current_state = PlayerEnums.playerState.CROUCH
		elif !stand_check.is_colliding() and grounded:
			if !is_moving:
				current_state = PlayerEnums.playerState.IDLE_STAND
			elif can_sprint:
				current_state = PlayerEnums.playerState.SPRINT
			else:
				current_state = PlayerEnums.playerState.WALK

	update_player_speed(current_state)
	update_player_collision(current_state)
	
func update_player_speed(_current_state: PlayerEnums.playerState) -> void:
	# SPEED MANAGEMENT BASED ON STATE / SERVER SIDE
	if not is_multiplayer_authority():
		return
	
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
	# CROUCH COLLISION SHAPE / SERVER SIDE
	if not is_multiplayer_authority():
		return
	
	if _current_state == PlayerEnums.playerState.CROUCH or _current_state == PlayerEnums.playerState.IDLE_CROUCH:
		standing_hitbox.disabled = true
		crouching_hitbox.disabled = false
		standing_mesh.visible = false
		crouching_mesh.visible = true
	else:
		standing_hitbox.disabled = false
		crouching_hitbox.disabled = true
		standing_mesh.visible = true
		crouching_mesh.visible = false

# JUMP ACTION
func perform_jump() -> void:
	
	if not is_multiplayer_authority():
		return
	
	if can_jump and grounded:
		player.velocity.y = jump_velocity

# GRAVITY ACTION
func handle_gravity(delta) -> void:
	
	if not is_multiplayer_authority():
		return
	
	if !grounded:
		player.velocity.y += gravity * delta

# CLIENT SIDE INPUT GATHERING
func handle_input() -> void:
	
	if not player.is_local:
		return
	
	var crouch_request: bool = true if Input.is_action_pressed("Crouch") else false
	var sprint_request: bool = true if Input.is_action_pressed("Sprint") and Input.is_action_pressed("Forward") and !can_crouch else false
	var jump_request: bool = true if Input.is_action_just_pressed("Jump") else false
	var input = player.input_gather()
	var dir = (camera_component.get_movement_direction(input))
	
	if multiplayer.get_unique_id() != 1:
		send_input.rpc_id(1, dir, crouch_request, sprint_request)
		send_jump_request.rpc_id(1, jump_request)
	else:
		send_input(dir, crouch_request, sprint_request)
		send_jump_request(jump_request)

# SERVER SIDE INPUT STASHING
@rpc("any_peer", "call_remote", "unreliable")
func send_input(_direction: Vector3, _can_crouch: bool, _can_sprint: bool) -> void:
	direction = _direction
	can_crouch = _can_crouch
	can_sprint = _can_sprint
	input_dir = Vector2(_direction.x, _direction.z)
	#print(direction, can_crouch, can_sprint, can_jump)

# SERVER SIDE JUMP REQ STASH
@rpc("any_peer", "call_remote", "reliable")
func send_jump_request(_jump_request: bool) -> void:
	can_jump = _jump_request

# SERVER SIDE MOVEMENT MATH
func handle_movement() -> void:
	if not is_multiplayer_authority():
		return
	var accel: float = g_accel if grounded else a_accel
	var true_direction = direction
	if true_direction != Vector3.ZERO:
		new_vel.x = lerp(new_vel.x, true_direction.x * speed, accel)
		new_vel.z = lerp(new_vel.z, true_direction.z * speed, accel)
		player.velocity.x = new_vel.x
		player.velocity.z = new_vel.z
	else:
		new_vel.x = lerp(new_vel.x, 0.0, accel)
		new_vel.z = lerp(new_vel.z, 0.0, accel)
		player.velocity.x = new_vel.x
		player.velocity.z = new_vel.z
	
	player.move_and_slide()

func get_moving() -> bool:
	moving = true if new_vel.length() > 0.1 else false
	return moving

func _physics_process(delta: float) -> void:
	# SERVER SIDE
	if not is_multiplayer_authority():
		return
	grounded = player.is_on_floor()
	update_player_state()
	# Gravity activation
	handle_gravity(delta)
	# Jump activation
	perform_jump()
	# Player velocity math
	handle_movement()
