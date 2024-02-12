extends Node3D

const StartScene = preload("res://scenes/screens/start_screen.tscn")
const HostSetupScene = preload("res://scenes/screens/host_setup_screen.tscn")
const JoinSetupScene = preload("res://scenes/screens/join_setup_screen.tscn")

@onready var current_screen = $GUI/StartScreen

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	if GlobalsConfig.get_data("fullscreen") == "true":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
		
	DisplayServer.window_set_min_size(Vector2i(1152, 648))
	
	GlobalSounds.play_menu_music()
	
	_mount_start_screen()

func _mount_start_screen():
	var start_screen = $GUI/StartScreen
	start_screen.host_game.connect(_handle_host_game)
	start_screen.join_game.connect(_handle_join_game)

func _mount_host_setup_screen():
	var setup_screen = $GUI/HostSetupScreen
	setup_screen.host_success.connect(_handle_host_success)
	setup_screen.back.connect(_handle_back)

func _mount_join_setup_screen():
	var setup_screen = $GUI/JoinSetupScreen
	setup_screen.join_success.connect(_handle_join_success)
	setup_screen.back.connect(_handle_back)

func _handle_host_game():
	_screen_transit(HostSetupScene)
	_mount_host_setup_screen()

func _handle_join_game():
	_screen_transit(JoinSetupScene)
	_mount_join_setup_screen()

func _handle_back():
	_screen_transit(StartScene)
	_mount_start_screen()

func _handle_host_success():
	get_tree().change_scene_to_file("res://scenes/main/main_game.tscn")

func _handle_join_success():
	get_tree().change_scene_to_file("res://scenes/main/main_game.tscn")

func _screen_transit(scene):
	current_screen.queue_free()
	
	var next_screen = scene.instantiate()
	$GUI.add_child(next_screen)
	
	current_screen = next_screen
