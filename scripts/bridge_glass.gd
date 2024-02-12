extends Node3D

@onready var static_body = $StaticBody3D
@onready var mesh_instance = $MeshInstance3D
@onready var audio_stream = $AudioStreamPlayer3D

var holds_weight = true
var is_broken = false
var particles = null
var glass_index = -1

const glass_broken_mesh = preload("res://meshes/bridge_glass_broken.tres")
const glass_mesh = preload("res://meshes/bridge_glass.tres")
const glass_pieces_scene = preload("res://scenes/bridge_glass_pieces.tscn")

signal broken(index)

func _on_area_3d_body_entered(body):
	if not holds_weight and not is_broken:
		break_glass.rpc()

func setup(_glass_index, _holds_weight, _is_broken):
	glass_index = _glass_index
	holds_weight = _holds_weight
	is_broken = _is_broken
	
	if holds_weight:
		static_body.collision_layer = Globals.Layers.DEFAULT
	else:
		static_body.collision_layer = Globals.Layers.BREAKABLE_GLASS
	
	if is_broken:
		mesh_instance.mesh = glass_broken_mesh
		static_body.collision_layer = Globals.Layers.PLAYER_IGNORED
	else:
		mesh_instance.mesh = glass_mesh
	
	var sound_index = randi_range(1, 3)
	audio_stream.stream = load("res://sounds/glass_break_" + str(sound_index) + ".wav")

@rpc("any_peer", "call_local", "reliable")
func break_glass():
	if not is_broken:
		is_broken = true
		mesh_instance.mesh = glass_broken_mesh
		static_body.collision_layer = Globals.Layers.PLAYER_IGNORED
		
		broken.emit(glass_index)
		
		var glass_pieces = glass_pieces_scene.instantiate()
		add_child(glass_pieces)
		
		audio_stream.play()
