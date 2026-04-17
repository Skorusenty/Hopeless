extends Control


func _on_host_pressed() -> void:
	Multiplayer._create_server()
	self.visible = false

func _on_join_pressed() -> void:
	Multiplayer._create_client()
	self.visible = false
