extends Node

var primary_color = Color(0.75, 0.25, 0.2593, 1)
var primary_hover_color = Color(0.6016, 0.196, 0.2035, 1)
var primary_shadow_color = Color(0.4314, 0.1569, 0.2196, 1)
var secondary_color = Color(0.2297, 0.2368, 0.3086, 1)
var secondary_hover_color = Color(0.204, 0.2073, 0.2695, 1)
var secondary_shadow_color = Color(0.1441, 0.1549, 0.2578, 1)
var font_color = Color.WHITE
var font_disabled_color = Color.LIGHT_SLATE_GRAY
var font_hover_color = Color.LIGHT_GRAY
var focus_border_color = Color(1, 1, 1, 0.2)
var error_color = Color("e36571")
var input_color = Color("202a33")
var input_disabled_color = Color("141a21")
var backdrop_color = Color(0, 0, 0, 0.8)
var paper_color = Color(0.0784, 0.102, 0.1294, 1)
var border_color = Color(0.1395, 0.1743, 0.2148, 1)
var border_radius = 8
var border_width = 2
var screen_background_color = Color("0b1015")

var variants = [
	{
		main = primary_color,
		hover = primary_hover_color,
		shadow = primary_shadow_color
	},
	{
		main = secondary_color,
		hover = secondary_hover_color,
		shadow = secondary_shadow_color
	}
]
