extends MultiplayerSpawner

@export var player_scene: PackedScene

func _ready() -> void:
	multiplayer.peer_connected.connect(_add_player)
	Multiplayer._register_spawner(self)


func _add_player(id: int) -> void:
	if not is_multiplayer_authority():
		return
	
	var player: Node = player_scene.instantiate()
	player.name = str(id)
	
	get_node(spawn_path).call_deferred("add_child", player)
