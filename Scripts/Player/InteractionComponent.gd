class_name InteractionComponent extends RayCast3D

@export var player: PlayerManager
@export var hovered_label: Label
var hovered_name
var hit

func _process(_delta: float) -> void:
	hover_collision()

func hover_collision() -> void:
	if not player.is_local:
		return
	if is_colliding():
		var hovered = get_collider()
		
		if hovered:
			if hovered.has_method("get_interactable_name"):
				hovered_label.text = "[E]" + hovered.get_interactable_name()
			else:
				hovered_label.text = "[E]" + hovered
	else:
		hovered_label.text = ""

func activate_request():
	if not player.is_local:
		return
	
	if not is_colliding():
		return
	var hit_interactable = get_collider()
	if multiplayer.get_unique_id() != 1:
		print("activate_request fired")
		activate.rpc_id(1, hit_interactable.get_path())
	else:
		activate(hit_interactable.get_path())

@rpc("any_peer", "call_remote", "reliable")
func activate(_hit: NodePath) -> void:
	hit = get_node_or_null(_hit)
	var player_interacting = player
	if not hit:
		print("Invalid hit")
		return
	
	if hit is Pickup:
		if hit.has_method("interact"):
			hit.interact(player_interacting)
			print("found the collider, hit.interact() fired")
