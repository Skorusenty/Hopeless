extends Node


var peer: ENetMultiplayerPeer
var ip: String = "localhost"
var port: int = 42069
var spawner: MultiplayerSpawner

func _register_spawner(_spawner: MultiplayerSpawner) -> void:
	spawner = _spawner
	
func _create_server() -> void:
	peer = ENetMultiplayerPeer.new()
	peer.create_server(port)
	multiplayer.multiplayer_peer = peer
	spawner._add_player(1)

func _create_client() -> void:
	peer = ENetMultiplayerPeer.new()
	peer.create_client(ip, port)
	multiplayer.multiplayer_peer = peer
