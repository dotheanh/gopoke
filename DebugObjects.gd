extends Node3D

func _ready():
	print("=== DEBUG ALL OBJECTS IN SCENE ===")
	_debug_node(self)

func _debug_node(node: Node, indent: String = ""):
	var info = indent + node.name
	
	# In vị trí nếu là Spatial/3D
	if node is Node3D:
		info += " | Position: " + str(node.global_transform.origin)
	
	# In các group
	if node.get_groups().size() > 0:
		info += " | Groups: " + str(node.get_groups())
	
	# In layer / collision nếu là physics body hoặc area
	if node is PhysicsBody3D or node is Area3D:
		info += " | Collision Layer: " + str(node.collision_layer)
		info += " | Collision Mask: " + str(node.collision_mask)
	
	# Nếu có CollisionShape3D con
	for child in node.get_children():
		if child is CollisionShape3D:
			var shape = child.shape
			if shape:
				if shape is BoxShape3D:
					info += " | BoxSize: " + str(shape.size)
				elif shape is SphereShape3D:
					info += " | SphereRadius: " + str(shape.radius)
				elif shape is CapsuleShape3D:
					info += " | CapsuleHeight: " + str(shape.height) + ", Radius: " + str(shape.radius)
				else:
					info += " | ShapeType: " + str(shape)
	
	print(info)
	
	# Duyệt tiếp các node con
	for child in node.get_children():
		_debug_node(child, indent + "  ")
