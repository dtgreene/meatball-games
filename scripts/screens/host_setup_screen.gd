extends Control

@onready var port_input = $VBoxContainer/VBoxContainer/HBoxContainer/PortInput/LineEdit
@onready var max_players_input = $VBoxContainer/VBoxContainer/HBoxContainer/MaxPlayersInput/LineEdit
@onready var setup_error = $VBoxContainer/VBoxContainer/SetupErrorLabel
@onready var host_error = $VBoxContainer/HostErrorLabel
@onready var host_button = $VBoxContainer/HBoxContainer/Host
@onready var back_button = $VBoxContainer/HBoxContainer/Back

signal host_success()
signal back()

func _ready():
	var saved_port = GlobalsConfig.get_data("host_port")
	var saved_max_players = GlobalsConfig.get_data("host_max_players")
	
	port_input.text = saved_port
	max_players_input.text = saved_max_players
	
	host_button.button_up.connect(_handle_host_click)
	back_button.button_up.connect(_handle_back_click)

func _handle_host_click():
	var port_value = int(port_input.text.strip_edges())
	var max_players_value = int(max_players_input.text.strip_edges())
	var error_text = null
	
	if port_value < 1024 or port_value >= 65535:
		error_text = "Please enter a valid port"
	if max_players_value < 2 or max_players_value >= 64:
		error_text = "Please enter a valid max player count"
	
	if error_text != null:
		setup_error.text = error_text
	else:
		GlobalsConfig.set_data("host_port", str(port_value))
		GlobalsConfig.set_data("host_max_players", str(max_players_value))
		
		setup_error.text = ""
		_disable_screen()
		
		var host_result = MPlay.host_game(port_value, max_players_value)
		
		if host_result == OK:
			host_success.emit()
		else:
			host_error.text = "Host failed (%s)" % host_result
			MPlay.peer_reset()
			_enable_screen()

func _handle_back_click():
	back.emit()

func _disable_screen():
	port_input.editable = false
	max_players_input.editable = false
	host_button.disable()
	back_button.disable()

func _enable_screen():
	port_input.editable = true
	max_players_input.editable = true
	host_button.enable()
	back_button.enable()
