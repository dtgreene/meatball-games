extends Control

const messages_show_time = 5
const winner_text_show_time = 8

@onready var pause_menu = $PauseMenu
@onready var pause_menu_main = $PauseMenu/Main
@onready var pause_menu_options = $PauseMenu/Options
@onready var messages_label = $ServerMessages/MarginContainer/Label
@onready var messages_timer = $ServerMessages/MessagesTimer
@onready var scoreboard = $Scoreboard
@onready var player_list = $Scoreboard/VBoxContainer/PlayerList
@onready var mouse_sensitivity_slider = $PauseMenu/Options/VBoxContainer/MarginContainer/VBoxContainer/MouseSensitivity/HSlider
@onready var music_volume_slider = $PauseMenu/Options/VBoxContainer/MarginContainer/VBoxContainer/MusicVolume/HSlider
@onready var winner_text = $WinnerText
@onready var winner_timer = $WinnerText/WinnerTimer
@onready var main_game = get_node("/root/MainGame")

var is_paused = false
var server_messages = []

signal mouse_sensitivity_changed(value)
signal game_paused()
signal game_resumed()

func _ready():
	#Engine.max_fps = 60
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	var resume_button = $PauseMenu/Main/VBoxContainer/Resume
	var options_button = $PauseMenu/Main/VBoxContainer/Options
	var reset_button = $PauseMenu/Main/VBoxContainer/Reset
	var leave_button = $PauseMenu/Main/VBoxContainer/Leave
	var quit_button = $PauseMenu/Main/VBoxContainer/Quit
	var back_button = $PauseMenu/Options/VBoxContainer/Back
	var fullscreen_button = $PauseMenu/Options/VBoxContainer/MarginContainer/VBoxContainer/Fullscreen/CheckButton
	
	resume_button.button_up.connect(_handle_resume_clicked)
	options_button.button_up.connect(_handle_options_clicked)
	leave_button.button_up.connect(_handle_leave_clicked)
	quit_button.button_up.connect(_handle_quit_clicked)
	back_button.button_up.connect(_handle_back_clicked)
	fullscreen_button.toggled.connect(_handle_fullscreen_toggled)
	
	if multiplayer.is_server():
		reset_button.button_up.connect(_handle_reset_clicked)
	else:
		reset_button.queue_free()
	
	# Initialize global configs
	mouse_sensitivity_slider.drag_ended.connect(_handle_mouse_sensitivity_drag)
	mouse_sensitivity_slider.value = float(GlobalsConfig.get_data("mouse_sensitivity"))
	music_volume_slider.drag_ended.connect(_handle_music_voluem_drag)
	music_volume_slider.value = float(GlobalsConfig.get_data("music_volume"))
	
	messages_timer.timeout.connect(_handle_messages_timeout)
	messages_timer.wait_time = messages_show_time
	
	winner_timer.timeout.connect(_handle_winner_timeout)
	winner_timer.wait_time = winner_text_show_time
	
	MPlay.mplay_peer_disconnected.connect(_handle_player_disconnected)
	MPlay.mplay_player_register.connect(_handle_player_register)
	
	# Initialize global configs
	if GlobalsConfig.get_data("fullscreen") == "true":
		fullscreen_button.button_pressed = true
	
	_add_player_label(MPlay.unique_id, GlobalsConfig.get_data("player_name"))

func _handle_resume_clicked():
	_resume_game()

func _handle_options_clicked():
	pause_menu_main.hide()
	pause_menu_options.show()

func _handle_reset_clicked():
	main_game.reset_game.rpc()

func _handle_leave_clicked():
	MPlay.peer_reset()
	get_tree().change_scene_to_file("res://scenes/main/main_start.tscn")

func _handle_quit_clicked():
	get_tree().quit()

func _handle_back_clicked():
	pause_menu_main.show()
	pause_menu_options.hide()

func _handle_fullscreen_toggled(value):
	if value:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
	
	GlobalsConfig.set_data("fullscreen", str(value))

func _handle_mouse_sensitivity_drag(value_changed):
	if value_changed:
		mouse_sensitivity_changed.emit(mouse_sensitivity_slider.value)
		GlobalsConfig.set_data("mouse_sensitivity", str(mouse_sensitivity_slider.value))

func _handle_music_voluem_drag(value_changed):
	if value_changed:
		GlobalsConfig.set_data("music_volume", str(music_volume_slider.value))
		GlobalSounds.set_music_volume(music_volume_slider.value)

func _handle_messages_timeout():
	messages_label.hide()

func _handle_winner_timeout():
	winner_text.hide()

func _handle_player_disconnected(id, _player_info):
	var label = player_list.get_node_or_null(str(id))
	
	if label:
		label.queue_free()

func _handle_player_register(id, player_info):
	_add_player_label(id, player_info.name)

func _add_player_label(id, player_name):
	var label = Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.name = str(id)
	label.text = player_name
	player_list.add_child(label)

func _pause_game():
	is_paused = true
	pause_menu.show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	game_paused.emit()

func _resume_game():
	is_paused = false
	pause_menu.hide()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	game_resumed.emit()

func show_winner_text(player_name):
	var winner_player_name = $WinnerText/VBoxContainer/PlayerName
	winner_player_name.text = player_name
	
	winner_text.show()
	winner_timer.start()

func _unhandled_input(event: InputEvent):
	if event is InputEventMouseButton and not is_paused:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _process(_delta):
	if Input.is_action_just_pressed("ui_cancel"):
		if is_paused:
			_resume_game()
		else:
			_pause_game()
			pause_menu_main.show()
			pause_menu_options.hide()
	
	if Input.is_action_pressed("show_scoreboard") and not is_paused:
		if not scoreboard.visible:
			scoreboard.show()
	elif scoreboard.visible:
		scoreboard.hide()

func _combine_messages(result, message):
	return result + "%s\n" % message

@rpc("reliable", "call_local")
func print_message(message):
	server_messages.push_back(message)
	
	if len(server_messages) > 5:
		server_messages.pop_front()
	
	messages_label.text = server_messages.reduce(_combine_messages, "")
	messages_label.show()
	messages_timer.start()
