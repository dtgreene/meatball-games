extends Node3D

const transition = 8.0
const walk_scale_min = 2.0
const walk_scale_max = 4.0

@onready var animation_tree = $AnimationTree

var animation_blend = 0.0

func update_animation(time_delta, walk_speed, is_falling, look_blend):
	if is_falling:
		animation_blend = lerpf(animation_blend, 1, time_delta * transition)
	else:
		var walk_scale = clampf(walk_speed + 1, walk_scale_min, walk_scale_max)
		animation_blend = lerpf(animation_blend, -walk_speed, time_delta * transition)
		animation_tree.set("parameters/WalkTimeScale/scale", walk_scale)
	
	animation_tree.set("parameters/LookAdd/add_amount", look_blend)
	animation_tree.set("parameters/MainBlend/blend_amount", animation_blend)
