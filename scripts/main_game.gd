extends Node3D

const player_scene = preload("res://scenes/player.tscn")
const peer_player_scene = preload("res://scenes/peer_player.tscn")
const glass_scene = preload("res://scenes/bridge_glass.tscn")
const glass_length = 28.0
const glass_rows = 10
const glass_spacing = glass_length / glass_rows

@onready var spawn_positions = [
	$Level/SpawnPosition1, 
	$Level/SpawnPosition2, 
	$Level/SpawnPosition3
]
@onready var level = $Level
@onready var disconnect_timer = $DisconnectTimer
@onready var late_register_timer = $LateRegisterTimer
@onready var gui_game = $GUIGame
@onready var peer_players = $Level/PeerPlayers

var state = _get_initial_state()
var peer_nodes = {}
var game_over = false

func get_player_spawn_position():
	return spawn_positions[randi_range(0, 2)].position

func _ready():
	MPlay.mplay_peer_disconnected.connect(_handle_player_disconnected)
	MPlay.mplay_server_disconnected.connect(_handle_server_disconnected)
	MPlay.mplay_player_register.connect(_handle_player_register)
	
	disconnect_timer.timeout.connect(_handle_disconnect_timeout)
	late_register_timer.timeout.connect(_handle_late_register_timeout)
	
	var kill_area = $Level/KillArea
	var win_area = $Level/WinArea
	var falling_area = $Level/FallingArea
	
	kill_area.body_shape_entered.connect(_handle_kill_area_entered)
	win_area.body_shape_entered.connect(_handle_win_area_entered)
	falling_area.body_shape_entered.connect(_handle_fall_area_entered)
	
	# Create the initial level state
	if multiplayer.is_server():
		# Apply the initial state locally for the host
		setup_game(state)
	else:
		# Disconnect if the setup message is not received after some time
		disconnect_timer.start()
	
	GlobalSounds.play_game_music()

func _create_glass(weights, broken):
	# Create the glass
	var glass_parent = $Level/BridgeGlass
	var scene = null
	var glass_index = -1
	
	for i in glass_rows:
		var holds_weight = bool(weights[i])
		
		# Add side 1
		glass_index = i * 2
		scene = glass_scene.instantiate()
		scene.name = "BridgeGlass%s" % glass_index
		scene.position = Vector3(-glass_length * 0.5 + glass_spacing + i * glass_spacing, -0.21, -1)
		scene.call_deferred("setup", glass_index, holds_weight, bool(broken[glass_index]))
		glass_parent.add_child(scene)
		scene.broken.connect(_handle_glass_broken)
		
		# Add side 2
		glass_index = i * 2 + 1
		scene = glass_scene.instantiate()
		scene.name = "BridgeGlass%s" % glass_index
		scene.position = Vector3(-glass_length * 0.5 + glass_spacing + i * glass_spacing, -0.21, 1)
		scene.call_deferred("setup", glass_index, not holds_weight, bool(broken[glass_index]))
		glass_parent.add_child(scene)
		scene.broken.connect(_handle_glass_broken)

func _leave_game():
	MPlay.peer_reset()
	get_tree().change_scene_to_file("res://scenes/main/main_start.tscn")

func _handle_kill_area_entered(body_rid, body, body_shape_index, local_body_index):
	var node_parent = _get_body_shape_parent(body, body_shape_index)
	
	if node_parent.is_in_group("players"):
		node_parent.kill()

func _handle_win_area_entered(body_rid, body, body_shape_index, local_body_index):
	if not game_over:
		var node_parent = _get_body_shape_parent(body, body_shape_index)
		
		if node_parent.is_in_group("players"):
			game_over = true
			set_game_over.rpc(GlobalsConfig.get_data("player_name"))

func _handle_fall_area_entered(body_rid, body, body_shape_index, local_body_index):
	var node_parent = _get_body_shape_parent(body, body_shape_index)
	
	if node_parent.is_in_group("players"):
		node_parent.falling()

func _get_body_shape_parent(body, body_shape_index):
	var body_shape_owner = body.shape_find_owner(body_shape_index)
	var body_shape_node = body.shape_owner_get_owner(body_shape_owner)
	
	return body_shape_node.get_parent()

func _handle_disconnect_timeout():
	Globals.start_message = "Setup timeout"
	_leave_game()

func _handle_late_register_timeout():
	for id in MPlay.players:
		if not peer_nodes.has(id) and id != MPlay.unique_id:
			call_deferred("_handle_player_register", id, MPlay.players[id])

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
		peer_player.player_info = player_info
		peer_nodes[id] = peer_player
		peer_players.add_child(peer_player)
	else:
		print_debug("Received duplicate player id: %s" % id)
	
	# Send the initial state to the new player
	if multiplayer.is_server():
		setup_game.rpc_id(id, state, _get_initial_peer_data())
		
		gui_game.print_message.rpc(
			"[SERVER]: %s joined" % player_info.name
		)

func _get_initial_peer_data():
	var result = {}
	var peer_player = null
	var data = null
	
	for key in MPlay.players:
		if peer_nodes.has(key):
			peer_player = peer_nodes[key]
			data = PackedByteArray()
			data.resize(16)
			data.encode_float(0, peer_player.position.x)
			data.encode_float(4, peer_player.position.y)
			data.encode_float(8, peer_player.position.z)
			data.encode_float(12, peer_player.rotation.y)
			result[key] = data
	
	return result

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
	state.glass_broken[index] = 0x1

@rpc("reliable")
func setup_game(server_state, peer_data = null):
	disconnect_timer.stop()
	
	_create_glass(server_state.glass_weights, server_state.glass_broken)
	
	# Set initial positions
	if peer_data:
		for key in peer_data:
			if peer_nodes.has(key):
				peer_nodes[key].initial_peer_sync(peer_data[key])
	
	# Spawn our player
	var our_player = player_scene.instantiate()
	peer_nodes[MPlay.unique_id] = our_player
	
	level.add_child(our_player)

@rpc("any_peer")
func peer_update(data):
	var peer_id = multiplayer.get_remote_sender_id()
	
	if peer_nodes.has(peer_id):
		peer_nodes[peer_id].peer_sync(data)

@rpc("any_peer", "reliable")
func peer_died():
	var peer_id = multiplayer.get_remote_sender_id()
	
	if peer_nodes.has(peer_id):
		peer_nodes[peer_id].play_death()

@rpc("any_peer", "reliable")
func peer_falling():
	var peer_id = multiplayer.get_remote_sender_id()
	
	if peer_nodes.has(peer_id):
		peer_nodes[peer_id].play_falling()

@rpc("reliable", "call_local")
func reset_game():
	get_tree().change_scene_to_file("res://scenes/main/main_game.tscn")

@rpc("any_peer", "reliable", "call_local")
func set_game_over(player_name):
	game_over = true
	gui_game.show_winner_text(player_name)
