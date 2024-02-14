@tool
extends EditorScript

func _run():
	#_prepare_glass_scenes()
	_prepare_player_character_scene()
	pass

func _prepare_player_character_scene():
	var glb_scene = load("res://models/player_character.glb")
	var glb_instance = glb_scene.instantiate()
	glb_instance.name = "PlayerCharacter"
	glb_instance.script = load("res://scripts/player_character.gd")
	
	#var head_attachment = BoneAttachment3D.new()
	#head_attachment.bone_name = "Head"
	#head_attachment.name = "HeadAttachment"
	#
	#var skeleton = glb_instance.get_node("Armature/Skeleton3D")
	#skeleton.add_child(head_attachment)
	#head_attachment.owner = glb_instance
	
	var animation_tree = AnimationTree.new()
	animation_tree.name = "AnimationTree"
	
	glb_instance.add_child(animation_tree)
	
	animation_tree.owner = glb_instance
	animation_tree.anim_player = "../AnimationPlayer"
	animation_tree.tree_root = load("res://animation_trees/player_character_blend.tres")
	
	_save_scene(glb_instance, "res://scenes/player_character.tscn")

func _prepare_glass_scenes():
	var timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = 4
	timer.autostart = true
	timer.name = "Timer"
	
	var root = Node3D.new()
	root.name = "BridgeGlassPieces"
	root.set_script(load("res://scripts/bridge_glass_pieces.gd"))
	root.add_child(timer)
	
	timer.owner = root
	
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(0.2, 0.02, 0.2)
	
	for i in 12:
		var glb_scene = load("res://models/bridge_glass_pieces_" + str(i + 1) + ".glb")
		var glb_instance = glb_scene.instantiate()
		var glb_mesh_instance = glb_instance.get_child(0)
		
		var mesh_instance = MeshInstance3D.new()
		mesh_instance.mesh = glb_mesh_instance.mesh
		mesh_instance.name = "MeshInstance3D"
		
		var collision_shape = CollisionShape3D.new()
		collision_shape.shape = box_shape
		collision_shape.name = "CollisionShape3D"
		
		var rigid_body = RigidBody3D.new()
		rigid_body.can_sleep = false
		rigid_body.mass = 1
		rigid_body.collision_layer = 0
		rigid_body.collision_mask = 0
		rigid_body.position = glb_mesh_instance.position
		rigid_body.name = "GlassPiece" + str(i)
		rigid_body.add_child(mesh_instance)
		rigid_body.add_child(collision_shape)
		
		root.add_child(rigid_body)
		
		rigid_body.owner = root
		mesh_instance.owner = root
		collision_shape.owner = root
	
	_save_scene(root, "res://scenes/bridge_glass_pieces.tscn")

func _save_scene(root, scene_path):
	var packed_scene = PackedScene.new()
	packed_scene.pack(root)
	
	var error = ResourceSaver.save(packed_scene, scene_path)
	
	if not error:
		print("Saving scene: " + scene_path)
