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
var _held_original_layer: int = 0
var _held_original_mask: int = 0
var my_id: int
## COMMENTED LINES FOR FURTHER UX (HUD/SOUNDS ETC)
#signal object_picked_up(obj: RigidBody3D)
#signal object_thrown(obj: RigidBody3D, force: float)
#signal object_placed(obj: RigidBody3D)
#signal object_dropped(obj: RigidBody3D)

func _ready() -> void:
	if is_multiplayer_authority():
		multiplayer.peer_disconnected.connect(_on_disconnect)
	my_id = multiplayer.get_unique_id()

func _on_disconnect(_id: int) -> void:
	if _held != null:
		_release(_held, Vector3.ZERO, _held.global_position)

func _input(_event: InputEvent) -> void:
	if not player.is_local:
		return
	print("CLIENT _held:", _held)
	# INTERACTIONS
	if Input.is_action_just_pressed("Interact"):
		if is_holding():
			request_place()
		else:
			interaction_component.activate_request()
			print("[E] pressed")
			
	if is_holding():
		if Input.is_action_just_pressed("Throw"):
			request_charge()
		if Input.is_action_just_released("Throw"):
			request_throw()
		
	if Input.is_action_just_pressed("Drop") and is_holding():
		request_drop()

func is_holding() -> bool:
	return _held != null

@rpc("authority", "reliable")
func sync_held(obj_path: NodePath) -> void:
	_held = get_node_or_null(obj_path)
	print("CLIENT now holding: ", _held)

func request_pick_up(obj: RigidBody3D) -> void:
	if not obj:
		return
		
	if is_multiplayer_authority():
		pick_up(obj.get_path(), my_id)
	else:
		pick_up.rpc_id(1, obj.get_path(), my_id)

@rpc("any_peer", "reliable")
func pick_up(obj_path: NodePath, sender_id: int) -> void:
	if not is_multiplayer_authority():
		return
	
	if _held != null:
		return
	
	var obj = get_node_or_null(obj_path)
	
	if not obj:
		return
	
	_held = obj
	if is_multiplayer_authority():
		sync_held.rpc_id(player.get_multiplayer_authority(), obj.get_path())
	_held_original_layer = obj.collision_layer
	_held_original_mask = obj.collision_mask
	
	_held.set_multiplayer_authority(sender_id)
	_held.freeze = true
	_held.collision_layer = 0
	_held.collision_mask = 0
	_held.linear_velocity = Vector3.ZERO
	_held.angular_velocity = Vector3.ZERO
	
	_held.global_transform = hold_point.global_transform
	
	player.movement_component.current_state = PlayerEnums.playerState.HOLDING
	print("RPC pick_up received on:", multiplayer.get_unique_id(), " server:", multiplayer.is_server())
	# COMMENTED LINES FOR FURTHER UX (HUD/SOUNDS ETC)
	#emit_signal("object_picked_up", _held)

func request_place() -> void:
	if _held == null:
		return
	
	var obj = _held
	
	if is_multiplayer_authority():
		place(obj.get_path())
	else:
		place.rpc_id(1, obj.get_path())

@rpc("any_peer", "reliable")
func place(obj_path: NodePath) -> void:
	if not is_multiplayer_authority():
		return
	
	if _held == null:
		return
	
	var obj = get_node_or_null(obj_path)
	
	if obj == null:
		return
	var place_pos = cam.global_position + (-cam.global_transform.basis.z * place_distance)
	
	if interaction_component.is_colliding():
		var result = interaction_component.get_collision_point()
		place_pos = result.position - (-cam.global_transform.basis.z * 0.1)
	
	_release(obj, Vector3.ZERO, place_pos)
	# COMMENTED LINES FOR FURTHER UX (HUD/SOUNDS ETC)
	#emit_signal("object_placed", obj)

func request_drop() -> void:
	if _held == null:
		return
	
	var obj = _held
	if is_multiplayer_authority():
		drop(obj.get_path())
	else:
		drop.rpc_id(1, obj.get_path())

@rpc("any_peer", "reliable")
func drop(obj_path: NodePath) -> void:
	if not is_multiplayer_authority():
		return
	
	if _held == null:
		return
	
	var obj = get_node_or_null(obj_path)
	
	if obj == null:
		return
	
	_release(obj, Vector3.ZERO, obj.global_position)
	# COMMENTED LINES FOR FURTHER UX (HUD/SOUNDS ETC)
	#emit_signal("object_dropped", obj)

func request_charge() -> void:
	if _held == null:
		return
	
	if is_multiplayer_authority():
		begin_charge()
	else:
		begin_charge.rpc_id(1)

func begin_charge() -> void:
	if not is_multiplayer_authority():
		return
	
	if _held == null:
		return
	
	_charging = true
	_charge_force = min_throw_force

func request_throw() -> void:
	if _held == null:
		return
	
	var obj = _held
	
	if is_multiplayer_authority():
		throw(obj.get_path())
	else:
		throw.rpc_id(1, obj.get_path())

@rpc("any_peer", "reliable")
func throw(obj_path: NodePath) -> void:
	if not is_multiplayer_authority():
		return
	
	if _held == null:
		return
	
	_charging = false
	var obj = get_node_or_null(obj_path)
	
	if obj == null:
		return
	# COMMENTED LINES FOR FURTHER UX (HUD/SOUNDS ETC)
	var dir = -cam.global_transform.basis.z
	#var force = _charge_force
	_release(obj, dir * _charge_force, obj.global_position)
	_charge_force = 0.0
	#emit_signal("object_thrown", obj, force)

func _release(obj: RigidBody3D, impulse: Vector3, targetPos: Vector3) -> void:
	_held = null
	_charging = false
	
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
	if not is_multiplayer_authority():
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
		request_drop()
		return
	
	if _charging:
		_charge_force = minf(_charge_force + charge_speed * delta, max_throw_force)
