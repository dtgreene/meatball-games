extends CharacterBody3D

const speed = 4.0
const acceleration = 8.0
const jump_velocity = 3.0
const gravity = 9.8
const mouse_multiplier = 0.01
const look_speed = 12.0
const min_x_rotation = deg_to_rad(-70)
const max_x_rotation = deg_to_rad(60)
const initial_rotation_y = -PI * 0.5
const position_update_rate = Globals.peer_update_rate
const position_update_min = 0.02
const rotation_update_min = 0.1
const animation_walk_threshold = 0.01
const animation_walk_factor = 16.0
# Use float() since high precision is needed
const mouse_scale = float(0.01)
const scream_threshold = 0.6
const push_strength = 16.0

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
var update_override = true
var can_push = true
var mouse_just_pressed = false
var disable_controls = false

@onready var camera = $Smoothing/Camera3D
@onready var breakable_ray_cast = $BreakableRayCast
@onready var push_ray_cast = $PushRayCast
@onready var respawn_timer = $RespawnTimer
@onready var main_game = get_node("/root/MainGame")
@onready var gui_game = get_node("/root/MainGame/GUIGame")
@onready var death_player = $DeathPlayer
@onready var falling_player = $FallingPlayer
@onready var push_player = $PushPlayer
@onready var push_impact_player = $PushImpactPlayer
@onready var player_character = $Smoothing/PlayerCharacter
@onready var update_override_timer = $UpdateOverrideTimer
@onready var push_reset_timer = $PushResetTimer
@onready var push_timer = $PushTimer

signal player_spawned()

func _ready():
	add_to_group("players")
	
	respawn_timer.timeout.connect(_handle_respawn_timeout)
	update_override_timer.timeout.connect(_handle_update_override_timeout)
	update_override_timer.start()
	push_reset_timer.timeout.connect(_handle_push_reset_timeout)
	push_timer.timeout.connect(_handle_push_timeout)
	
	gui_game.mouse_sensitivity_changed.connect(_handle_mouse_sensitivity_changed)
	gui_game.game_paused.connect(_handle_game_paused)
	gui_game.game_resumed.connect(_handle_game_resumed)
	
	# Set the shadow setting
	var player_mesh = $Smoothing/PlayerCharacter/Armature/Skeleton3D/Character
	player_mesh.cast_shadow = MeshInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
	
	mouse_sensitivity = float(GlobalsConfig.get_data("mouse_sensitivity"))
	
	respawn()

func _unhandled_input(event):
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			target_rotation_y = target_rotation_y - event.relative.x * mouse_sensitivity * mouse_scale
			target_camera_rotation_x = target_camera_rotation_x - event.relative.y * mouse_sensitivity * mouse_scale
			target_camera_rotation_x = clamp(target_camera_rotation_x, min_x_rotation, max_x_rotation)
		elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			mouse_just_pressed = true

func _handle_mouse_sensitivity_changed(value):
	mouse_sensitivity = value

func _handle_game_paused():
	disable_controls = true

func _handle_game_resumed():
	disable_controls = false

func _process(delta):
	rotation_y = lerpf(rotation_y, target_rotation_y, delta * look_speed)
	rotation.y = rotation_y
	camera_rotation_x = lerpf(camera_rotation_x, target_camera_rotation_x, delta * look_speed)
	camera.rotation.x = camera_rotation_x

func _physics_process(delta):
	var current_is_on_floor = is_on_floor()
	var move_direction = null
	
	if not current_is_on_floor:
		velocity.y -= gravity * delta
	
	if is_alive and not disable_controls:
		var input_direction = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
		move_direction = (transform.basis * Vector3(input_direction.x, 0, input_direction.y)).normalized()
		
		if current_is_on_floor and Input.is_action_just_pressed("jump"):
			# Prevents jumping when colliding with glass panels that are about to break
			if breakable_ray_cast.get_collider() == null:
				velocity.y = jump_velocity
		
		if mouse_just_pressed and can_push:
			can_push = false
			main_game.peer_push.rpc()
			player_character.push()
			push_reset_timer.start()
			push_timer.start()
	
	if move_direction != null:
		velocity.x = lerpf(velocity.x, move_direction.x * speed, delta * acceleration)
		velocity.z = lerpf(velocity.z, move_direction.z * speed, delta * acceleration)
	else:
		velocity.x = lerpf(velocity.x, 0.0, delta * acceleration)
		velocity.z = lerpf(velocity.z, 0.0, delta * acceleration)
	
	move_and_slide()
	
	position_tick += 1
	if position_tick >= position_update_rate or update_override:
		position_tick = 0
		
		var position_needs_update = (position - prev_position).length() > position_update_min
		var rotation_needs_update = (
			abs(prev_rotation_x - camera.rotation.x) > rotation_update_min or
			abs(prev_rotation_y - rotation.y) > rotation_update_min
		)
		
		if position_needs_update or rotation_needs_update or update_override:
			main_game.peer_update.rpc(get_update_data())
		
		prev_position = position
		prev_rotation_x = camera.rotation.x
		prev_rotation_y = rotation.y
	
	var walk_mag = get_position_delta().length()
	var walk_speed = clampf(walk_mag * animation_walk_factor, 0.0, 1.0) if walk_mag > animation_walk_threshold else 0.0
	var look_blend = remap(camera.rotation.x, min_x_rotation, max_x_rotation, -1.0, 1.0)
	player_character.update_animation(delta, walk_speed, not current_is_on_floor, look_blend)
	
	mouse_just_pressed = false

func _handle_respawn_timeout():
	respawn()

func _handle_update_override_timeout():
	update_override = false

func _handle_push_reset_timeout():
	can_push = true

func _handle_push_timeout():
	if is_alive:
		push_player.play()
		push_ray_cast.force_raycast_update()
		
		if push_ray_cast.is_colliding():
			var collider = push_ray_cast.get_collider()
			var collider_parent = collider.get_parent()
			
			if collider_parent.is_in_group("peer_players"):
				main_game.peer_push_peer.rpc(collider_parent.unique_id)
				push_impact_player.play()

func respawn():
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
	
	player_spawned.emit()

func play_push_impact():
	push_impact_player.play()

func get_pushed(from_position):
	var push_direction = (position - from_position).normalized()
	velocity += push_direction * push_strength

func enable_update_override():
	update_override = true
	update_override_timer.start()

func fall():
	if randf() > scream_threshold:
		falling_player.play()
		main_game.peer_fall.rpc()

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
