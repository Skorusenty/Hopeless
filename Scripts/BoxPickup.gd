class_name BoxPickup extends Pickup

@export var prompt_text: String = "PICK UP!"
@export var can_pickup: bool = true

signal prompt_shown(text: String)
signal prompt_hidden()

func interact() -> void:
	if !can_pickup:
		return
		
	var pick = get_tree().get_first_node_in_group("Player")
	if pick and pick.has_method("get_pickup_comp"):
		pick.get_pickup_comp().pick_up(self)
		
func show_prompt() -> void:
	emit_signal("prompt_shown", prompt_text)

func hide_prompt() -> void:
	emit_signal("prompt_hidden")
