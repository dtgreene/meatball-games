extends CharacterBody3D

const speed = 4.0
const acceleration = 8.0
const jump_velocity = 3.0
const gravity = 9.8
const mouse_multiplier = 0.01
const look_speed = 12.0
const min_x_rotation = deg_to_rad(-80)
const max_x_rotation = deg_to_rad(80)
const initial_rotation_y = -PI * 0.5
const position_update_rate = Globals.peer_update_rate
const position_update_min = 0.02
const rotation_update_min = 0.1
const animation_walk_threshold = 0.01
const animation_walk_factor = 16.0
# Use float() since high precision is needed
const mouse_scale = float(0.01)
const scream_threshold = 0.6

var rotation_y = 0.0
var target_rotation_y = 0.0
var camera_rotation_x = 0.0
var target_camera_rotation_x = 0.0
var is_alive = true
var prev_position = position
var prev_rotation_x = 0.0
var prev_rotation_y = 0.0
var position_tick = 0
var mouse_sensitivity = 1.0

@onready var camera = $Smoothing/Camera3D
@onready var breakable_ray_cast = $BreakableRayCast
@onready var respawn_timer = $RespawnTimer
@onready var main_game = get_node("/root/MainGame")
@onready var loading_text = get_node("/root/MainGame/GUIGame/LoadingText")
@onready var gui_game = get_node("/root/MainGame/GUIGame")
@onready var death_player = $DeathPlayer
@onready var falling_player = $FallingPlayer
@onready var player_character = $Smoothing/PlayerCharacter

func _ready():
	add_to_group("players")
	
	respawn_timer.timeout.connect(_handle_respawn_timeout)
	
	gui_game.mouse_sensitivity_changed.connect(_handle_mouse_sensitivity_changed)
	
	# Set the shadow setting
	var player_mesh = $Smoothing/PlayerCharacter/Armature/Skeleton3D/Character
	player_mesh.cast_shadow = MeshInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
	
	mouse_sensitivity = float(GlobalsConfig.get_data("mouse_sensitivity"))
	
	_respawn()

func _unhandled_input(event):
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			target_rotation_y = target_rotation_y - event.relative.x * mouse_sensitivity * mouse_scale
			target_camera_rotation_x = target_camera_rotation_x - event.relative.y * mouse_sensitivity * mouse_scale
			target_camera_rotation_x = clamp(target_camera_rotation_x, min_x_rotation, max_x_rotation)

func _handle_mouse_sensitivity_changed(value):
	mouse_sensitivity = value

func _process(delta):
	rotation_y = lerpf(rotation_y, target_rotation_y, delta * look_speed)
	rotation.y = rotation_y
	camera_rotation_x = lerpf(camera_rotation_x, target_camera_rotation_x, delta * look_speed)
	camera.rotation.x = camera_rotation_x

func _physics_process(delta):
	if is_alive:
		var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
		var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		
		if not is_on_floor():
			velocity.y -= gravity * delta
		elif Input.is_action_just_pressed("jump"):
			# Prevents jumping when colliding with glass panels that are about to break
			if breakable_ray_cast.get_collider() == null or true:
				velocity.y = jump_velocity
		
		if direction:
			velocity.x = lerpf(velocity.x, direction.x * speed, delta * acceleration)
			velocity.z = lerpf(velocity.z, direction.z * speed, delta * acceleration)
		else:
			velocity.x = lerpf(velocity.x, 0.0, delta * acceleration)
			velocity.z = lerpf(velocity.z, 0.0, delta * acceleration)
		
		move_and_slide()
	
	position_tick += 1
	if position_tick >= position_update_rate:
		position_tick = 0
		
		var position_needs_update = (position - prev_position).length() > position_update_min
		var rotation_needs_update = (
			abs(prev_rotation_x - camera.rotation.x) > rotation_update_min or 
			abs(prev_rotation_y - rotation.y) > rotation_update_min
		)
		
		if position_needs_update or rotation_needs_update:
			main_game.peer_update.rpc(get_update_data())
		
		prev_position = position
		prev_rotation_x = camera.rotation.x
		prev_rotation_y = rotation.y
	
	var walk_mag = get_position_delta().length()
	var walk_speed = clampf(walk_mag * animation_walk_factor, 0.0, 1.0) if walk_mag > animation_walk_threshold else 0
	var look_blend = remap(camera.rotation.x, min_x_rotation, max_x_rotation, -1.0, 1.0)
	player_character.update_animation(delta, walk_speed, not is_on_floor(), look_blend)

func _respawn():
	is_alive = true
	
	# Get spawn position
	position = main_game.get_player_spawn_position()
	
	# Reset rotation
	rotation_y = initial_rotation_y
	target_rotation_y = initial_rotation_y
	rotation.y = initial_rotation_y
	camera_rotation_x = 0.0
	target_camera_rotation_x = 0.0
	camera.rotation.x = 0.0
	
	# Update sync values
	prev_position = position
	prev_rotation_x = camera.rotation.x
	prev_rotation_y = rotation.y
	
	if not camera.current:
		camera.current = true
	
	if loading_text.visible:
		loading_text.call_deferred("hide")

func _handle_respawn_timeout():
	_respawn()

func falling():
	if randf() > scream_threshold:
		falling_player.play()
		main_game.peer_falling.rpc()

func kill():
	is_alive = false
	respawn_timer.start()
	death_player.play()
	main_game.peer_died.rpc()

func get_update_data():
	var data = PackedByteArray()
	data.resize(20)
	data.encode_float(0, position.x)
	data.encode_float(4, position.y)
	data.encode_float(8, position.z)
	data.encode_float(12, camera.rotation.x)
	data.encode_float(16, rotation.y)
	
	return data
