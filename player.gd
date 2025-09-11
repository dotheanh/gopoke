extends CharacterBody3D

# --- CONFIG ---
var speed := 5.0
var orbit_angle_speed := 3.0  # tốc độ quay quanh target
var zoom_speed := 20.0        # tốc độ tiến/lùi quanh target
@export var max_hp := 100
@export var anim_player: AnimationPlayer

# --- NODES ---
@onready var camera: Camera3D = $CameraPivot/Camera3D
@onready var marker: MeshInstance3D = MeshInstance3D.new()

# --- STATE ---
var current_target: Node = null
var orbit_angle: float = 0.0
var orbit_radius: float = 3.0  # giá trị mặc định nếu muốn
var hp: int

signal hp_changed(current: int, max: int)

func _ready():
	anim_player.play("Idle")
	GameManagerGlobal.player = self
	hp = max_hp
	GameManagerGlobal.register_player(self)
	emit_signal("hp_changed", hp, max_hp)
	
	# Khởi tạo marker
	marker.mesh = SphereMesh.new()
	marker.scale = Vector3(0.3, 0.3, 0.3)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color.RED
	marker.material_override = mat
	add_child(marker)
	marker.visible = false

func take_damage(amount: int) -> void:
	hp = max(0, hp - amount)
	print("Player took", amount, "damage. HP =", hp)
	emit_signal("hp_changed", hp, max_hp)
	if hp == 0:
		die()

func heal(amount: int) -> void:
	hp = clamp(hp + amount, 0, max_hp)
	emit_signal("hp_changed", hp, max_hp)

func die() -> void:
	print("Player died!")
	queue_free()
	GameManagerGlobal.on_player_died()

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
	marker.global_transform.origin = target_node.global_transform.origin + Vector3(0, 3, 0)
	
	var flat_player_pos = Vector3(global_transform.origin.x, target_node.global_transform.origin.y, global_transform.origin.z)
	orbit_radius = (flat_player_pos - target_node.global_transform.origin).length()
	orbit_angle = atan2(global_transform.origin.z - target_node.global_transform.origin.z,
						global_transform.origin.x - target_node.global_transform.origin.x)
	
	print("Locked target:", target_node.name, "Orbit radius:", orbit_radius)

func _physics_process(delta):
	if current_target:
		# Marker luôn bám đầu target
		marker.global_transform.origin = current_target.global_transform.origin + Vector3(0, 2, 0)
		
		# --- Input orbit trái/phải ---
		var orbit_input = 0
		if Input.is_key_pressed(Key.KEY_LEFT):
			orbit_input += 1
		if Input.is_key_pressed(Key.KEY_RIGHT):
			orbit_input -= 1
		
		if orbit_input != 0:
			orbit_angle += orbit_input * orbit_angle_speed * delta
		
		# --- Input tiến/lùi (up/down) ---
		var zoom_input = 0
		if Input.is_key_pressed(Key.KEY_UP):
			zoom_input -= 1
		if Input.is_key_pressed(Key.KEY_DOWN):
			zoom_input += 1
		
		if zoom_input != 0:
			orbit_radius += zoom_input * delta * zoom_speed
			orbit_radius = max(1.0, orbit_radius)
		
		var target_pos = current_target.global_transform.origin
		
		# Vị trí Player theo orbit_angle và orbit_radius
		var new_pos = Vector3(
			target_pos.x + orbit_radius * cos(orbit_angle),
			global_transform.origin.y,
			target_pos.z + orbit_radius * sin(orbit_angle)
		)
		global_transform.origin = new_pos
		
		# Player nhìn về target, mượt
		var desired_rotation = (target_pos - global_transform.origin).normalized()
		var current_forward = -global_transform.basis.z
		var lerped_dir = current_forward.lerp(desired_rotation, delta * 10.0).normalized()
		look_at(global_transform.origin + lerped_dir, Vector3.UP)
