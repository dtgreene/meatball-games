extends Node

var players = {}
var unique_id = -1

signal mplay_peer_connected(id)
signal mplay_peer_disconnected(id, player_info)
signal mplay_connected_to_server()
signal mplay_connection_failed()
signal mplay_server_disconnected()
signal mplay_player_register(id, player_info)

func _ready():
	multiplayer.peer_connected.connect(_handle_player_connected)
	multiplayer.peer_disconnected.connect(_handle_player_disconnected)
	multiplayer.connected_to_server.connect(_handle_connected_ok)
	multiplayer.connection_failed.connect(_handle_connected_fail)
	multiplayer.server_disconnected.connect(_handle_server_disconnected)

func _get_player_info():
	var player_name = GlobalsConfig.get_data("player_name")
	return { "name": player_name }

func _handle_player_connected(id):
	# Send the joining player our info
	_register_player.rpc_id(id, _get_player_info())
	mplay_peer_connected.emit(id)

func _handle_player_disconnected(id):
	var player_info = null
	if players.has(id):
		player_info = players[id]
	
	players.erase(id)
	mplay_peer_disconnected.emit(id, player_info)

func _handle_connected_ok():
	# Register self
	var peer_id = multiplayer.get_unique_id()
	players[peer_id] = _get_player_info()
	mplay_connected_to_server.emit()
	unique_id = peer_id

func _handle_connected_fail():
	peer_reset()
	mplay_connection_failed.emit()

func _handle_server_disconnected():
	peer_reset()
	mplay_server_disconnected.emit()

func host_game(port, max_players):
	var peer = ENetMultiplayerPeer.new()
	var result = peer.create_server(port, max_players)
	
	if result == OK:
		multiplayer.multiplayer_peer = peer
		# Register self
		players[1] = _get_player_info()
		unique_id = 1
	
	return result

func join_game(ip_address, port):
	var peer = ENetMultiplayerPeer.new()
	var result = peer.create_client(ip_address, port)
	
	if result == OK:
		multiplayer.multiplayer_peer = peer
	
	return result

func peer_reset():
	players = {}
	unique_id = -1
	multiplayer.multiplayer_peer = null

@rpc("any_peer", "reliable")
func _register_player(new_player_info):
	var new_player_id = multiplayer.get_remote_sender_id()
	players[new_player_id] = new_player_info
	mplay_player_register.emit(new_player_id, new_player_info)
