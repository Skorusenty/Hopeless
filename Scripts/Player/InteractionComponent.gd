class_name InteractionComponent extends RayCast3D

@export var player: PlayerManager
var hovered

func hover_collision() -> void:
	if self.is_colliding():
		hovered = self.get_collider()
		if hovered is Pickup:
			if hovered.has_method("show_prompt"):
				hovered.show_prompt()
			else:
				hovered.hide_prompt()

func activate():
	var hit = self.get_collider()
	if self.is_colliding():
		if hit is Pickup:
			if hit.has_method("interact"):
				hit.interact()
