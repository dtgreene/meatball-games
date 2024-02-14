extends Control

const width = 1000
const height = 150
const y_margin = 20
const font_size = 128
const font = preload("res://fonts/ProtestStrike-Regular.ttf")

var position_value = 0

func _ready():
	set_custom_minimum_size(Vector2(width, height))

func _draw():
	var text_position = Vector2(0, height * 0.5 + sin(position_value) * 4.0)
	
	draw_string(
		font, 
		text_position + Vector2(8.0, 0.0), 
		"MEATBALL GAMES", 
		HORIZONTAL_ALIGNMENT_CENTER, 
		width,
		font_size,
		CustomTheme.primary_color
	)
	draw_string(
		font, 
		text_position, 
		"MEATBALL GAMES", 
		HORIZONTAL_ALIGNMENT_CENTER, 
		width, 
		font_size
	)

func _process(delta):
	position_value += delta * 4.0
	queue_redraw()
