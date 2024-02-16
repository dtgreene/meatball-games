extends Node3D

const player_scene = preload("res://scenes/player.tscn")
const peer_player_scene = preload("res://scenes/peer_player.tscn")
const glass_scene = preload("res://scenes/bridge_glass.tscn")
const glass_length = 28.0
const glass_rows = 10
const glass_spacing = glass_length / glass_rows
const spawn_origin = Vector3(-20, 1.0, 0.0)

@onready var level = $Level
@onready var disconnect_timer = $DisconnectTimer
@onready var gui_game = $GUIGame
@onready var peer_players = $Level/PeerPlayers

var state = {
	glass_weights = [],
	glass_broken = []
}
var peer_nodes = {}
var game_over = false

func get_player_spawn_position():
	return Vector3(spawn_origin.x + randf_range(-2.5, 2.5), spawn_origin.y, spawn_origin.z + randf_range(-3.0, 3.0))

func _ready():
	MPlay.mplay_peer_disconnected.connect(_handle_player_disconnected)
	MPlay.mplay_server_disconnected.connect(_handle_server_disconnected)
	MPlay.mplay_player_register.connect(_handle_player_register)
	
	disconnect_timer.timeout.connect(_handle_disconnect_timeout)
	
	var kill_area = $Level/KillArea
	var win_area = $Level/WinArea
	var falling_area = $Level/FallingArea
	
	kill_area.body_shape_entered.connect(_handle_kill_area_entered)
	win_area.body_shape_entered.connect(_handle_win_area_entered)
	falling_area.body_shape_entered.connect(_handle_fall_area_entered)
	
	reset_game()
	
	GlobalSounds.play_game_music()

func _handle_player_spawned():
	gui_game.hide_loading_text()

func _create_glass(weights, broken):
	# Create the glass
	var glass_parent = $Level/BridgeGlass
	
	var scene = null
	var glass_index = -1
	var glass_name = ""
	
	for i in glass_rows:
		var holds_weight = bool(weights[i])
		
		# Add side 1
		glass_index = i * 2
		glass_name = "BridgeGlass%s" % glass_index
		scene = glass_parent.get_node_or_null(glass_name)
		
		if scene == null:
			scene = glass_scene.instantiate()
			scene.name = glass_name
			scene.position = Vector3(-glass_length * 0.5 + glass_spacing + i * glass_spacing, -0.21, -1)
			scene.broken.connect(_handle_glass_broken)
			glass_parent.add_child(scene)
		
		scene.call_deferred("setup", glass_index, holds_weight, bool(broken[glass_index]))
		
		# Add side 2
		glass_index = i * 2 + 1
		glass_name = "BridgeGlass%s" % glass_index
		scene = glass_parent.get_node_or_null(glass_name)
		
		if scene == null:
			scene = glass_scene.instantiate()
			scene.name = glass_name
			scene.position = Vector3(-glass_length * 0.5 + glass_spacing + i * glass_spacing, -0.21, 1)
			scene.broken.connect(_handle_glass_broken)
			glass_parent.add_child(scene)
		
		scene.call_deferred("setup", glass_index, not holds_weight, bool(broken[glass_index]))

func _leave_game():
	MPlay.peer_reset()
	get_tree().change_scene_to_file("res://scenes/main/main_start.tscn")

func _handle_kill_area_entered(_body_rid, body, body_shape_index, _local_body_index):
	var node_parent = _get_body_shape_parent(body, body_shape_index)
	
	if node_parent.is_in_group("players"):
		node_parent.kill()

func _handle_win_area_entered(_body_rid, body, body_shape_index, _local_body_index):
	if not game_over:
		var node_parent = _get_body_shape_parent(body, body_shape_index)
		
		if node_parent.is_in_group("players"):
			game_over = true
			set_game_over.rpc(GlobalsConfig.get_data("player_name"))

func _handle_fall_area_entered(_body_rid, body, body_shape_index, _local_body_index):
	var node_parent = _get_body_shape_parent(body, body_shape_index)
	
	if node_parent.is_in_group("players"):
		node_parent.fall()

func _get_body_shape_parent(body, body_shape_index):
	var body_shape_owner = body.shape_find_owner(body_shape_index)
	var body_shape_node = body.shape_owner_get_owner(body_shape_owner)
	
	return body_shape_node.get_parent()

func _handle_disconnect_timeout():
	Globals.start_message = "Setup timeout"
	_leave_game()

func _handle_server_disconnected():
	Globals.start_message = "Server disconnected"
	_leave_game()

func _handle_player_disconnected(id, player_info):
	if multiplayer.is_server():
		if player_info:
			gui_game.print_message.rpc(
				"[SERVER]: %s left" % player_info.name
			)
	
	if peer_nodes.has(id):
		peer_nodes[id].queue_free()
		peer_nodes.erase(id)

func _handle_player_register(id, player_info):
	# Spawn the connected player
	if not peer_nodes.has(id):
		var peer_player = peer_player_scene.instantiate()
		peer_player.player_name = player_info.name
		peer_player.unique_id = id
		peer_nodes[id] = peer_player
		peer_players.add_child(peer_player)
		
		var our_player = get_node_or_null("/root/MainGame/Level/Player")
		
		if our_player != null:
			our_player.enable_update_override()
		
		# Send the initial state to the new player
		if multiplayer.is_server():
			gui_game.print_message.rpc(
				"[SERVER]: %s joined" % player_info.name
			)
	else:
		print_debug("Received duplicate player id: %s" % id)

func _get_initial_state():
	var glass_weights = PackedByteArray()
	var glass_broken = PackedByteArray()
	
	for i in glass_rows:
		glass_weights.push_back(0x0 if randf() > 0.5 else 0x1)
		glass_broken.push_back(0x0)
		glass_broken.push_back(0x0)
	
	return {
		glass_weights = glass_weights,
		glass_broken = glass_broken
	}

func _handle_glass_broken(index):
	if multiplayer.is_server():
		state.glass_broken[index] = 0x1

func _create_player():
	var our_player = get_node_or_null("/root/MainGame/Level/Player")
	
	if our_player == null:
		our_player = player_scene.instantiate()
		our_player.player_spawned.connect(_handle_player_spawned)
		
		level.add_child(our_player)
	
	return our_player

@rpc("reliable", "any_peer")
func request_setup():
	var peer_id = multiplayer.get_remote_sender_id()
	
	if multiplayer.is_server():
		setup_game.rpc_id(peer_id, state)
	else:
		print_debug("Non-server received setup request: %s" % peer_id)

@rpc("reliable")
func setup_game(server_state):
	if not disconnect_timer.is_stopped():
		disconnect_timer.stop()
	
	_create_player()
	_create_glass(server_state.glass_weights, server_state.glass_broken)

@rpc("any_peer")
func peer_update(data):
	var peer_id = multiplayer.get_remote_sender_id()
	
	if peer_nodes.has(peer_id):
		peer_nodes[peer_id].peer_sync(data)

@rpc("any_peer")
func peer_fall():
	var peer_id = multiplayer.get_remote_sender_id()
	
	if peer_nodes.has(peer_id):
		peer_nodes[peer_id].play_fall()

@rpc("any_peer")
func peer_push():
	var peer_id = multiplayer.get_remote_sender_id()
	
	if peer_nodes.has(peer_id):
		peer_nodes[peer_id].push()

@rpc("any_peer")
func peer_push_peer(id):
	var peer_id = multiplayer.get_remote_sender_id()
	var our_player = get_node_or_null("/root/MainGame/Level/Player")
	
	if our_player != null:
		our_player.play_push_impact()
		
		if MPlay.unique_id == id and peer_nodes.has(peer_id):
			our_player.get_pushed(peer_nodes[peer_id].position)

@rpc("any_peer", "reliable")
func peer_died():
	var peer_id = multiplayer.get_remote_sender_id()
	
	if peer_nodes.has(peer_id):
		peer_nodes[peer_id].play_death()

@rpc("reliable", "call_local")
func reset_game():
	gui_game.show_loading_text()
	
	if multiplayer.is_server():
		state = _get_initial_state()
		setup_game(state)
	else:
		# Disconnect if the setup message is not received from the server after some time
		disconnect_timer.start()
		request_setup.rpc_id(1)
	
	var our_player = get_node_or_null("/root/MainGame/Level/Player")
	
	if our_player != null:
		our_player.respawn()

@rpc("any_peer", "reliable", "call_local")
func set_game_over(player_name):
	game_over = true
	gui_game.show_winner_text(player_name)
