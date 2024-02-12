extends Control

const width = 600
const height = 64
const top_margin = 32
const font_size = 24
const font_height_offset = 8
const height_range = height + top_margin
const down_transition = 2
const up_transition = 4

@onready var default_font = get_theme_default_font()
@onready var idle_timer = $IdleTimer

enum States {
	TRANSIT_DOWN,
	IDLE,
	TRANSIT_UP
}

var background_box = StyleBoxFlat.new()
var drop_value = 0 
var state = States.TRANSIT_DOWN
var message = ""

func _ready():
	idle_timer.timeout.connect(_handle_idle_timeout)
	
	set_custom_minimum_size(Vector2(width, height))
	
	background_box.set_corner_radius_all(8)
	background_box.set_border_width_all(2)
	background_box.border_color = CustomTheme.border_color
	background_box.bg_color = CustomTheme.paper_color

func _draw():
	draw_style_box(background_box, Rect2(0, top_margin, width, height))
	draw_string(
		default_font, 
		Vector2(0, height * 0.5 + font_height_offset + top_margin), 
		message, 
		HORIZONTAL_ALIGNMENT_CENTER, 
		width, 
		font_size
	)

func _process(delta):
	match state:
		States.TRANSIT_DOWN:
			if drop_value < 1:
				drop_value = clamp(drop_value + down_transition * delta, 0, 1)
				position.y = -height_range + _ease_out_bounce(drop_value) * height_range
			else:
				state = States.IDLE
				idle_timer.start()
		States.TRANSIT_UP:
			if drop_value < 1:
				drop_value = clamp(drop_value + up_transition * delta, 0, 1)
				position.y = -height_range * drop_value
			else:
				queue_free()

func _handle_idle_timeout():
	drop_value = 0
	state = States.TRANSIT_UP

func _ease_out_bounce(x):
	var n1 = 7.5625
	var d1 = 2.75
	
	if x < 1 / d1:
		return n1 * x * x
	else:
		var xx = 0
		var offset = 0
		
		if x < 2 / d1:
			xx = x - 1.5 / d1
			offset = 0.75
		elif x < 2.5 / d1:
			xx = x - 2.25 / d1
			offset = 0.9375
		else:
			xx = x - 2.625 / d1
			offset = 0.984375
		
		return n1 * xx * xx + offset
