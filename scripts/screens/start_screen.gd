extends Control

const ToastScene = preload("res://scenes/toast.tscn")

@onready var name_input = $VBoxContainer/VBoxContainer/NameInput/LineEdit
@onready var name_error = $VBoxContainer/VBoxContainer/NameInput/ErrorLabel
@onready var host_button = $VBoxContainer/VBoxContainer/Host
@onready var join_button = $VBoxContainer/VBoxContainer/Join
@onready var exit_button = $VBoxContainer/VBoxContainer/Exit

signal host_game()
signal join_game()

func _ready():
	var saved_name = GlobalsConfig.get_data("player_name")
	
	name_input.grab_focus()
	name_input.text = saved_name
	name_input.caret_column = len(saved_name)
	
	host_button.button_up.connect(_handle_host_click)
	join_button.button_up.connect(_handle_join_click)
	exit_button.button_up.connect(_handle_exit_click)
	
	# Check if there is a start message (ex. server disconnect)
	# This allows showing messages from the game on the start screen
	if len(Globals.start_message) > 0:
		var toast = ToastScene.instantiate()
		toast.message = Globals.start_message
		
		add_child(toast)
		
		Globals.start_message = ""

func _handle_host_click():
	if _sync_player_name():
		host_game.emit()

func _handle_join_click():
	if _sync_player_name():
		join_game.emit()

func _sync_player_name():
	var name_value = name_input.text.strip_edges()
	var error_text = null
	
	if len(name_value) == 0:
		error_text = "Please enter a name"
	elif len(name_value) > name_input.max_length:
		error_text = "Please use a shorter name"
	
	if error_text != null:
		name_error.text = error_text
		return false
	else:
		GlobalsConfig.set_data("player_name", name_value)
		
		name_error.text = ""
		return true

func _handle_exit_click():
	get_tree().quit()
