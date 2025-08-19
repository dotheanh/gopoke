extends CharacterBody3D

# --- CONFIG ---
var speed := 5.0
var orbit_angle_speed := 1.0  # tốc độ quay quanh target

# --- NODES ---
@onready var camera: Camera3D = $CameraPivot/Camera3D
@onready var marker: MeshInstance3D = MeshInstance3D.new()

# --- STATE ---
var current_target: Node = null
var orbit_angle: float = 0.0
var orbit_radius: float = 3.0  # giá trị mặc định nếu muốn

func _ready():
	# Khởi tạo marker
	marker.mesh = SphereMesh.new()
	marker.scale = Vector3(0.3, 0.3, 0.3)
	
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color.RED
	marker.material_override = mat
	
	add_child(marker)
	marker.visible = false

func _input(event):
	# CLICK để lock target
	if event is InputEventMouseButton and event.pressed:
		var cam = get_viewport().get_camera_3d()
		if not cam:
			print("No active camera found!")
			return
		
		var from = cam.project_ray_origin(event.position)
		var dir = cam.project_ray_normal(event.position)
		var to = from + dir * 100
		
		var params = PhysicsRayQueryParameters3D.new()
		params.from = from
		params.to = to
		params.collision_mask = 1
		params.exclude = [self]
		
		var space_state = get_world_3d().direct_space_state
		var result = space_state.intersect_ray(params)
		
		if result:
			var collider = result.collider
			if collider.is_in_group("Enemy"):
				lock_target(collider)
		else:
			print("Ray missed")

func lock_target(target_node: Node) -> void:
	current_target = target_node
	marker.visible = true
	marker.global_transform.origin = target_node.global_transform.origin + Vector3(0, 2, 0)
	
	# Khởi tạo orbit_radius từ khoảng cách Player -> target trên mặt phẳng XZ
	var flat_player_pos = Vector3(global_transform.origin.x, target_node.global_transform.origin.y, global_transform.origin.z)
	orbit_radius = (flat_player_pos - target_node.global_transform.origin).length()
	
	# Tính góc ban đầu dựa theo vị trí Player so với target
	orbit_angle = atan2(global_transform.origin.z - target_node.global_transform.origin.z,
						global_transform.origin.x - target_node.global_transform.origin.x)
	
	print("Locked target:", target_node.name, "Orbit radius:", orbit_radius)

func _physics_process(delta):
	if current_target:
		# Marker luôn bám đầu target
		marker.global_transform.origin = current_target.global_transform.origin + Vector3(0, 2, 0)
		
		# --- Input orbit
		var input_dir = 0
		if Input.is_key_pressed(Key.KEY_LEFT):
			input_dir += 1
		if Input.is_key_pressed(Key.KEY_RIGHT):
			input_dir -= 1
		
		if input_dir != 0:
			orbit_angle += input_dir * orbit_angle_speed * delta
			var target_pos = current_target.global_transform.origin
			
			# Orbit quanh target, giữ y của Player
			var new_pos = Vector3(
				target_pos.x + orbit_radius * cos(orbit_angle),
				global_transform.origin.y,  # giữ chiều cao hiện tại
				target_pos.z + orbit_radius * sin(orbit_angle)
			)
			global_transform.origin = new_pos
			
			# Player luôn nhìn về target (trên mặt phẳng XZ)
			var desired_rotation = (target_pos - global_transform.origin).normalized()
			var current_forward = -global_transform.basis.z

			# Lerp hướng nhìn mượt
			var lerped_dir = current_forward.lerp(desired_rotation, delta * 10.0).normalized()

			look_at(global_transform.origin + lerped_dir, Vector3.UP)
