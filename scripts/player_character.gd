extends Node3D

const transition = 8.0
const walk_scale_min = 2.0
const walk_scale_max = 4.0

@onready var animation_tree = $AnimationTree

var main_blend = 0.0
var push_blend = 0.0
var is_pushing = true

func _ready():
	animation_tree.animation_finished.connect(_handle_animation_finished)

func _handle_animation_finished(anim_name):
	if anim_name == "Push":
		is_pushing = false

func update_animation(time_delta, walk_speed, is_falling, look_add):
	if is_falling:
		main_blend = lerpf(main_blend, 1.0, time_delta * transition)
	else:
		var walk_scale = clampf(walk_speed + 1.0, walk_scale_min, walk_scale_max)
		main_blend = lerpf(main_blend, -walk_speed, time_delta * transition)
		animation_tree.set("parameters/WalkTimeScale/scale", walk_scale)
	
	if is_pushing:
		push_blend = lerpf(push_blend, 1.0, time_delta * transition)
	else:
		push_blend = lerpf(push_blend, 0.0, time_delta * transition)
	
	animation_tree.set("parameters/PushBlend/blend_amount", push_blend)
	animation_tree.set("parameters/LookAdd/add_amount", look_add)
	animation_tree.set("parameters/MainBlend/blend_amount", main_blend)

func push():
	is_pushing = true
	animation_tree.set("parameters/PushTimeSeek/seek_request", 0.0)
