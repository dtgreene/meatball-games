extends Node

@onready var click_player = $ClickPlayer
@onready var music_player = $MusicPlayer

var menu_music = null
var game_music = null

func _ready():
	menu_music = load("res://sounds/rollin.mp3")
	game_music = load("res://sounds/polygon_paradise.mp3")
	
	menu_music.loop = true
	game_music.loop = true
	
	# Initialize global configs
	var saved_volume = float(GlobalsConfig.get_data("music_volume"))
	set_music_volume(saved_volume)

func play_click():
	click_player.play()

func set_music_volume(value):
	music_player.volume_db = remap(value, 0.0, 1.0, -32, -10)

func play_menu_music():
	music_player.stream = menu_music
	
	if music_player.playing:
		music_player.seek(0)
	else:
		music_player.play()

func play_game_music():
	music_player.stream = game_music
	
	if music_player.playing:
		music_player.seek(0)
	else:
		music_player.play()
