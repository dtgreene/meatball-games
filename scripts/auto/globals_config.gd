extends Node

const default_data = {
	player_name = "Player",
	host_port = "3074",
	host_max_players = "8",
	join_ip = "127.0.0.1",
	join_port = "3074",
	mouse_sensitivity = "1.0",
	music_volume = "1.0",
	fullscreen = "true"
}
const config_path = "user://user.cfg"
const base_section = "User"

var config = ConfigFile.new()

func _ready():
	var result = config.load(config_path)
	
	if result == OK:
		# Initially set the default data
		if not config.has_section(base_section):
			for key in default_data.keys():
				config.set_value(base_section, key, default_data[key])
		
		# Add any missing default data
		for key in default_data.keys():
			if not config.has_section_key(base_section, key):
				config.set_value(base_section, key, default_data[key])
		
		# Erase any unknown sections
		for section_key in config.get_sections():
			if section_key != base_section:
				config.erase_section(section_key)
		
		# Erase any unknown section keys
		for key in config.get_section_keys(base_section):
			if not default_data.has(key):
				config.erase_section_key(base_section, key)

func set_data(key, value):
	assert(typeof(value) == TYPE_STRING, "Received non-string value: " + str(value))
	config.set_value(base_section, key, value)
	config.save(config_path)

func get_data(key):
	return config.get_value(base_section, key)
