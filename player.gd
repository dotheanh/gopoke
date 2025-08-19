extends CharacterBody3D

var current_target : Node = null

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		var cam = get_viewport().get_camera_3d()
		if not cam:
			print("No active camera found!")
			return
		
		var from = cam.project_ray_origin(event.position)
		var dir = cam.project_ray_normal(event.position)
		var to = from + dir * 100  # ray dài 100 units
		
		# debug ray
		print("Ray from ", from, " to ", to)
		
		# Tạo parameters cho Godot 4
		var params = PhysicsRayQueryParameters3D.new()
		params.from = from
		params.to = to
		params.collision_mask = 1  # phải trùng layer Enemy
		params.exclude = [self]     # loại trừ Player nếu muốn
		
		var space_state = get_world_3d().direct_space_state
		var result = space_state.intersect_ray(params)
		
		if result:
			var collider = result.collider
			print("Ray hit: ", collider.name)
			if collider.is_in_group("Enemy"):
				lock_target(collider)
		else:
			print("Ray missed")
			# Debug khoảng cách đến tất cả Enemy
			for enemy in get_tree().get_nodes_in_group("Enemy"):
				var dir_to_enemy = (enemy.global_transform.origin - from).normalized()
				var dist = from.distance_to(enemy.global_transform.origin)
				print(enemy.name, "direction: ", dir_to_enemy, "distance: ", dist)

func lock_target(target_node: Node) -> void:
	current_target = target_node
	print("Locked target: ", target_node.name)

func _physics_process(delta):
	if current_target:
		var target_pos = current_target.global_transform.origin
		var dir = (target_pos - global_transform.origin).normalized()
		look_at(target_pos, Vector3.UP)
		velocity = dir * 5   # gán velocity
		move_and_slide()      # Godot 4 không nhận tham số
