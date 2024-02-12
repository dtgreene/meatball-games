extends Control

@onready var ip_input = $VBoxContainer/VBoxContainer/HBoxContainer/IPInput/LineEdit
@onready var port_input = $VBoxContainer/VBoxContainer/HBoxContainer/PortInput/LineEdit
@onready var setup_error = $VBoxContainer/VBoxContainer/SetupErrorLabel
@onready var join_error = $VBoxContainer/JoinErrorLabel
@onready var join_button = $VBoxContainer/HBoxContainer/Join
@onready var back_button = $VBoxContainer/HBoxContainer/Back
@onready var join_timer = $JoinTimer

signal join_success()
signal back()

var ip_regex = RegEx.create_from_string("^[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}$")

func _ready():
	var saved_ip = GlobalsConfig.get_data("join_ip")
	var saved_port = GlobalsConfig.get_data("join_port")
	
	ip_input.text = saved_ip
	port_input.text = saved_port
	
	join_button.button_up.connect(_handle_join_click)
	back_button.button_up.connect(_handle_back_click)
	
	join_timer.timeout.connect(_handle_join_timeout)
	
	MPlay.mplay_connected_to_server.connect(_handle_connected_to_server)
	MPlay.mplay_connection_failed.connect(_handle_connection_failed)

func _handle_join_click():
	var ip_value = ip_input.text.strip_edges()
	var port_value = int(port_input.text.strip_edges())
	var error_text = null
	
	var ip_matches = ip_regex.search(ip_value)
	
	if ip_matches == null:
		error_text = "Please enter a valid address"
	elif port_value < 1024 or port_value >= 65535:
		error_text = "Please enter a valid port"
	
	if error_text != null:
		setup_error.text = error_text
	else:
		GlobalsConfig.set_data("join_ip", ip_value)
		GlobalsConfig.set_data("join_port", str(port_value))
		
		setup_error.text = ""
		_disable_screen()
		
		var join_result = MPlay.join_game(ip_value, port_value)
		
		if join_result == OK:
			join_timer.start()
		else:
			join_error.text = "Join failed (%s)" % join_result
			MPlay.peer_reset()
			_enable_screen()

func _handle_back_click():
	back.emit()

func _handle_join_timeout():
	join_error.text = "Join failed (timed out)"
	_enable_screen()
	
	MPlay.peer_reset()

func _handle_connected_to_server():
	join_timer.stop()
	join_success.emit()

func _handle_connection_failed():
	join_timer.stop()
	join_error.text = "Join failed"
	_enable_screen()

func _disable_screen():
	ip_input.editable = false
	port_input.editable = false
	join_button.disable()
	back_button.disable()

func _enable_screen():
	ip_input.editable = true
	port_input.editable = true
	join_button.enable()
	back_button.enable()

