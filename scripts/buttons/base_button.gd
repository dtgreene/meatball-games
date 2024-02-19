extends Control

# Transition time in 1 / hover_transition seconds
const hover_transition = 15
const press_transition = 40
const focus_radius = 8
const focus_margin = 4

@export_group("Base Button")
@export var text = ""
@export var is_disabled = false
@export var disabled_modulate = Color(1, 1, 1, 0.5)
@export var width = 300
@export var height = 40
@export var font_size = 24
@export var bottom_margin = 16
@export var font_height_offset = 8
@export var font_color = Color.WHITE
@export var font_disabled_color = Color.LIGHT_SLATE_GRAY
@export var font_hover_color = Color.LIGHT_GRAY
@export var variant_index = 0

@onready var default_font = get_theme_default_font()

var is_hovered = false
var hover_strength = 0
var press_strength = 0
var is_focused = false
var is_pressed = false
var focus_box = StyleBoxFlat.new()
var focus_rect = Rect2(-focus_margin, -focus_margin, width + focus_margin * 2, height + focus_margin * 2)
var palette = CustomTheme.variants[variant_index]

signal button_up

func _ready():
	set_custom_minimum_size(Vector2(width, height + bottom_margin))
	
	focus_box.set_corner_radius_all(CustomTheme.border_radius)
	focus_box.set_border_width_all(CustomTheme.border_width)
	focus_box.border_color = CustomTheme.focus_border_color
	focus_box.draw_center = false
	
	palette = CustomTheme.variants[variant_index]

func _draw():
	if is_focused:
		draw_style_box(focus_box, focus_rect)

func _gui_input(event):
	var is_mouse_left = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT
	if not is_disabled and is_hovered and is_mouse_left and not event.pressed:
		_button_up()

func _notification(what):
	match what:
		NOTIFICATION_MOUSE_ENTER:
			is_hovered = true
		NOTIFICATION_MOUSE_EXIT:
			is_hovered = false
		NOTIFICATION_FOCUS_ENTER:
			is_focused = true
		NOTIFICATION_FOCUS_EXIT:
			is_focused = false

func _button_up():
	button_up.emit()
	GlobalSounds.play_click()

func _process(delta):
	if not is_disabled:
		var needs_update = false
		
		if is_hovered:
			if hover_strength < 1:
				hover_strength += delta * hover_transition
				needs_update = true
		else:
			if hover_strength > 0:
				hover_strength -= delta * hover_transition
				needs_update = true
			
			if is_pressed:
				is_pressed = false
				needs_update = true
		
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			if is_hovered and not is_pressed:
				is_pressed = true
				needs_update = true
		elif is_pressed:
			is_pressed = false
			needs_update = true
		
		if is_focused:
			if Input.is_action_pressed("ui_accept"):
				if not is_pressed:
					is_pressed = true
					needs_update = true
			elif Input.is_action_just_released("ui_accept"):
				_button_up()
		
		if is_pressed:
			if press_strength < 1:
				press_strength += delta * press_transition
				needs_update = true
		else:
			if press_strength > 0:
				press_strength -= delta * press_transition
				needs_update = true
		
		if needs_update:
			hover_strength = clamp(hover_strength, 0, 1)
			press_strength = clamp(press_strength, 0, 1)
			queue_redraw()

func enable():
	is_disabled = false
	queue_redraw()

func disable():
	is_disabled = true
	queue_redraw()
