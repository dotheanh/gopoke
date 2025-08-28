# projectile.gd
extends Area3D
class_name Projectile

@export var speed: float = 10.0
@export var damage: int = 30
@export var radius: float = 1.0  # bán kính va chạm
var target_pos: Vector3

# Mesh hiển thị
var mesh_instance: MeshInstance3D

func _ready():
	# Tạo mesh hình cầu màu cam
	mesh_instance = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radial_segments = 16
	sphere.rings = 8
	sphere.radius = 0.5  # default radius, có thể set lại sau
	mesh_instance.mesh = sphere
	mesh_instance.scale = Vector3.ONE
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1, 0.5, 0)
	mesh_instance.material_override = mat
	add_child(mesh_instance)

	# Sync scale theo radius hiện tại
	_update_mesh_scale()

func _update_mesh_scale():
	if mesh_instance:
		mesh_instance.scale = Vector3.ONE * radius

func _physics_process(delta):
	if not target_pos:
		return
	var dir = target_pos - global_transform.origin
	var distance = dir.length()
	if distance < 0.1:
		hit_target()
		return
	dir = dir.normalized()
	var move_dist = min(speed * delta, distance)
	global_translate(dir * move_dist)

func hit_target():
	if GameManagerGlobal.player:
		var player_pos = GameManagerGlobal.player.global_transform.origin
		var dist = (Vector3(player_pos.x, 0, player_pos.z) - Vector3(global_transform.origin.x, 0, global_transform.origin.z)).length()
		if dist <= radius:
			GameManagerGlobal.player.take_damage(damage)
			print("Player hit by", name, "for", damage, "HP")
	queue_free()
