extends "res://scripts/buttons/base_button.gd"

@export_group("3D Button")
@export var press_distance = 6

var background_box = StyleBoxFlat.new()
var shadow_box = StyleBoxFlat.new()

func _ready():
	super()
	
	background_box.bg_color = palette.main
	background_box.set_corner_radius_all(CustomTheme.border_radius)
	shadow_box.bg_color = palette.shadow
	shadow_box.set_corner_radius_all(CustomTheme.border_radius)
	
	focus_rect = Rect2(
		-focus_margin, 
		-focus_margin, 
		width + focus_margin * 2, 
		height + focus_margin * 2 + press_distance
	)

func _draw():
	super()
	
	var press_offset = press_distance * press_strength
	var color = CustomTheme.font_color.lerp(CustomTheme.font_hover_color, hover_strength)
	
	if is_disabled:
		press_offset = 0
		color = CustomTheme.font_disabled_color
		background_box.bg_color = palette.main
		modulate = disabled_modulate
	else:
		background_box.bg_color = palette.main.lerp(palette.hover, hover_strength)
		modulate = Color.WHITE
	
	draw_style_box(shadow_box, Rect2(0, press_distance, width, height))
	draw_style_box(background_box, Rect2(0, press_offset, width, height))
	
	draw_string(
		default_font,
		Vector2(0, height * 0.5 + font_height_offset + press_offset), 
		text, 
		HORIZONTAL_ALIGNMENT_CENTER, 
		width, 
		font_size, 
		color
	)
