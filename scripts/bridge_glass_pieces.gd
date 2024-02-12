extends Node3D

func _ready():
	$DeleteTimer.timeout.connect(_handle_delete_timeout)
	
	var rand_mid = Vector3(0.5, 0.5, 0.5)
	for child in get_children():
		if child is RigidBody3D:
			child.apply_central_impulse((Vector3(randf(), randf() - 1, randf()) - rand_mid) * 3.0)
			child.apply_torque((Vector3(randf(), randf(), randf()) - rand_mid) * 4.0)

func _handle_delete_timeout():
	queue_free()
