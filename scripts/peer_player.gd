extends Node3D

const lerp_speed = 60.0 / Globals.peer_update_rate
const teleport_delta_threshold = 0.5
const animation_delta = 1.0 / 60.0
const animation_walk_threshold = 0.01
const animation_walk_factor = 18.0
const min_x_rotation = deg_to_rad(-80)
const max_x_rotation = deg_to_rad(80)

@onready var name_label = $NameLabel
@onready var death_player = $DeathPlayer
@onready var falling_player = $FallingPlayer
@onready var player_character = $PlayerCharacter
@onready var floor_ray_cast = $FloorRayCast

var target_position = position
var target_rotation_x = rotation.x
var target_rotation_y = rotation.y
var rotation_x = rotation.x
var prev_position_delta = Vector3()
var received_sync = false
var player_info = null

func _ready():
	name_label.text = player_info.name

func _process(delta):
	var current_position = position
	
	position = position.lerp(target_position, delta * lerp_speed)
	rotation_x = lerpf(rotation_x, target_rotation_x, delta * lerp_speed)
	rotation.y = lerpf(rotation.y, target_rotation_y, delta * lerp_speed)
	
	var position_mag = (position - current_position).length()
	
	floor_ray_cast.force_raycast_update()
	
	var walk_speed = clampf(position_mag * animation_walk_factor, 0.0, 1.0) if position_mag > animation_walk_threshold else 0
	var is_falling = not floor_ray_cast.is_colliding()
	var look_blend = remap(rotation_x, min_x_rotation, max_x_rotation, -1.0, 1.0)
	player_character.update_animation(animation_delta, walk_speed, is_falling, look_blend)

func peer_sync(data):
	var new_target_position = Vector3(
		data.decode_float(0),
		data.decode_float(4),
		data.decode_float(8)
	)
	var position_delta = target_position - new_target_position
	var is_teleport = (position_delta - prev_position_delta).length() > teleport_delta_threshold
	
	# If the current delta is much greater than the previous delta, move instantly
	if is_teleport:
		position = new_target_position
		prev_position_delta = Vector3()
	else:
		prev_position_delta = position_delta
	
	target_position = new_target_position
	target_rotation_x = data.decode_float(12)
	
	# We dont actually want to lerp here but rather use the lerp_angle as a utility.
	# This prevents the character from spinning all the way around when transitioning from -PI to PI.
	target_rotation_y = lerp_angle(target_rotation_y, data.decode_float(16), 1)
	
	# If we receive sync updates before the initial sync update
	if not received_sync:
		received_sync = true
		show()

func initial_peer_sync(data):
	if not received_sync:
		var new_position = Vector3(
			data.decode_float(0),
			data.decode_float(4),
			data.decode_float(8)
		)
		
		position = new_position
		target_position = new_position
		
		rotation.y = lerp_angle(rotation.y, data.decode_float(12), 1)
		target_rotation_y = rotation.y
		
		received_sync = true
		show()

func play_death():
	death_player.play()

func play_falling():
	falling_player.play()
