extends "res://scripts/buttons/base_button.gd"

func _draw():
	var color = CustomTheme.font_color.lerp(CustomTheme.font_hover_color, hover_strength)
	
	if is_disabled:
		color = CustomTheme.font_disabled_color
		modulate = disabled_modulate
	else:
		modulate = Color.WHITE
	
	draw_string(
		default_font, 
		Vector2(0, height * 0.5 + font_height_offset), 
		text, 
		HORIZONTAL_ALIGNMENT_CENTER, 
		width, 
		font_size, 
		color
	)
	
	super()
