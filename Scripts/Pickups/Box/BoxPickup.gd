class_name BoxPickup extends Pickup

@export var prompt_text: String
@export var can_pickup: bool = true

func interact() -> void:
	if !can_pickup:
		return
		
	var pick = get_tree().get_first_node_in_group("Player")
	if pick and pick.has_method("get_pickup_comp"):
		pick.get_pickup_comp().pick_up(self)

func get_interactable_name() -> String:
	return prompt_text
