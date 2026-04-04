class_name PickupComponent extends Node3D

@export_category("References")
@export var player: PlayerManager
@export var cam: CameraComponent
@export var hold_point: Marker3D
@export var interaction_component: InteractionComponent

@export_category("Hold Settings")
@export var hold_lerp_speed: float = 15.0
@export var hold_rot_lerp_speed: float = 10.0
@export var max_hold_distance: float = 3.5

@export_category("Throw Settings")
@export var min_throw_force: float = 8.0
@export var max_throw_force: float = 60.0
@export var charge_speed: float = 16.0

@export_category("Place Settings")
@export var place_distance: float = 2.0

var _held: RigidBody3D = null
var _charge_force: float = 0.0
var _charging: bool = false
var _held_original_parent: Node = null
var _held_original_layer: int = 0
var _held_original_mask: int = 0

signal object_picked_up(obj: RigidBody3D)
signal object_thrown(obj: RigidBody3D, force: float)
signal object_placed(obj: RigidBody3D)
signal object_dropped(obj: RigidBody3D)

func _input(_event: InputEvent) -> void:
	if not Multiplayer.is_local:
		return
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
		if is_holding():
			place()
		else:
			interaction_component.activate()
			
	if is_holding():
		if Input.is_action_just_pressed("Throw"):
			begin_charge()
		if Input.is_action_just_released("Throw"):
			throw()
		
	if Input.is_action_just_pressed("Drop") and is_holding():
		drop()

func is_holding() -> bool:
	return _held != null

func pick_up(obj: RigidBody3D) -> void:
	if not Multiplayer.is_local:
		return
	if _held != null:
		return
	_held = obj
	_held_original_parent = obj.get_parent()
	_held_original_layer = obj.collision_layer
	_held_original_mask = obj.collision_mask
	
	_held.freeze = true
	_held.collision_layer = 0
	_held.collision_mask = 0
	
	_held_original_parent.remove_child(_held)
	hold_point.add_child(_held)
	_held.global_transform = hold_point.global_transform
	
	player.movement_component.current_state = PlayerEnums.playerState.HOLDING
	emit_signal("object_picked_up", _held)
	
func place() -> void:
	if not Multiplayer.is_local:
		return
	if _held == null:
		return
	var obj = _held
	var place_pos = cam.global_position + (-cam.global_transform.basis.z * place_distance)
	_release(obj, Vector3.ZERO, place_pos)
	emit_signal("object_placed", obj)
	
func begin_charge() -> void:
	if not Multiplayer.is_local:
		return
	if _held == null:
		return
	_charging = true
	_charge_force = min_throw_force

func throw() -> void:
	if not Multiplayer.is_local:
		return
	if _held == null:
		return
	_charging = false
	var obj = _held
	var dir = -cam.global_transform.basis.z
	_release(obj, dir * _charge_force, obj.global_position)
	_charge_force = 0.0
	emit_signal("object_thrown", obj, _charge_force)
	
func drop() -> void:
	if not Multiplayer.is_local:
		return
	if _held == null:
		return
	var obj = _held
	_release(obj, Vector3.ZERO, obj.global_position)
	emit_signal("object_dropped", obj)
	
func _release(obj: RigidBody3D, impulse: Vector3, targetPos: Vector3) -> void:
	if not Multiplayer.is_local:
		return
	_held = null
	_charging = false
	
	hold_point.remove_child(obj)
	_held_original_parent.add_child(obj)
	obj.global_position = targetPos
	
	obj.freeze = false
	obj.collision_layer = _held_original_layer
	obj.collision_mask = _held_original_mask
	
	if impulse != Vector3.ZERO:
		obj.linear_velocity = impulse
		obj.linear_velocity = obj.linear_velocity.limit_length(40.0)
		
		obj.angular_velocity = Vector3(
			randf_range(0.0, 2.0),
			randf_range(0.0, 2.0),
			randf_range(0.0, 2.0)
		)
	
	if player.movement_component.current_state == PlayerEnums.playerState.HOLDING:
		player.movement_component.current_state = PlayerEnums.playerState.IDLE_STAND
		
func _physics_process(delta: float) -> void:
	if not Multiplayer.is_local:
		return
	if _held == null:
		return
	
	_held.global_position = _held.global_position.lerp(
		hold_point.global_position, delta * hold_lerp_speed
	)
	
	var target_quat = Quaternion(hold_point.global_transform.basis.orthonormalized())
	var current_quat = Quaternion(_held.global_transform.basis.orthonormalized())
	_held.global_transform.basis = Basis(current_quat.slerp(target_quat, delta * hold_rot_lerp_speed))
	
	if _held.global_position.distance_to(hold_point.global_position) > max_hold_distance:
		drop()
		return
	
	if _charging:
		_charge_force = minf(_charge_force + charge_speed * delta, max_throw_force)
