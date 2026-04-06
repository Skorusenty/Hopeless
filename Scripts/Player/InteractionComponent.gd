class_name InteractionComponent extends RayCast3D

@export var player: PlayerManager
@export var hovered_label: Label
var hovered_name
var hit

func _process(delta: float) -> void:
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

func activate():
	if not player.is_local:
		return
	var hit_interactable = get_collider()
	if multiplayer.get_unique_id() != 1:
		activate_request.rpc_id(1, hit_interactable)
	else:
		activate_request(hit_interactable)

@rpc("any_peer", "call_remote", "reliable")
func activate_request(_hit) -> void:
	if not is_multiplayer_authority():
		return
	print("dildo")
	hit = _hit
	if self.is_colliding():
		if hit is Pickup:
			if hit.has_method("interact"):
				hit.interact()
