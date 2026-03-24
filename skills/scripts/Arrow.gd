# Arrow.gd
# Skill bắn tên đường thẳng từ caster đến target position.
# Indicator hiển thị đường bay từ caster → target.
# Override hit logic để nhận biết target cụ thể (monster đang lock).

extends SkillBase
class_name ArrowSkill

# Biến riêng cho Arrow
var _arrow_instance: Area3D

# Override: indicator ở giữa đường bay caster→target
func get_indicator_position(target_pos: Vector3) -> Vector3:
	if caster == null or not is_instance_valid(caster):
		return target_pos
	var caster_pos := caster.global_transform.origin + Vector3(0, 0.5, 0)
	var end_pos := target_pos + Vector3(0, 0.5, 0)
	return caster_pos.lerp(end_pos, 0.5)

# Override: xoay indicator theo hướng bay + scale chiều dài theo khoảng cách
func show_indicator(target_pos: Vector3):
	if caster == null or not is_instance_valid(caster):
		return
	var indicator = AreaIndicator.new()
	var caster_pos := caster.global_transform.origin
	var flight_dist := caster_pos.distance_to(target_pos)
	# Tạo box dài bằng khoảng cách bay, mỏng dọc hướng bắn
	indicator.setup(data.shape, Vector3(data.size.x, data.size.y, flight_dist))
	var current_scene = GameManagerGlobal.get_tree().get_current_scene()
	current_scene.add_child(indicator)
	# Đặt ở giữa đường bay, nâng nhẹ lên mặt đất
	var mid := caster_pos.lerp(target_pos, 0.5) + Vector3(0, 0.15, 0)
	indicator.global_transform.origin = mid
	# Xoay indicator nhìn về target
	indicator.look_at(target_pos + Vector3(0, 0.15, 0), Vector3.UP)
	await Engine.get_main_loop().create_timer(data.cast_time).timeout
	indicator.queue_free()

func execute(target_pos: Vector3) -> void:
	if caster == null or not is_instance_valid(caster):
		return

	# Lưu locked target trước khi tạo arrow
	var locked_target = caster.get_meta("locked_target") if caster.has_meta("locked_target") else null
	var caster_name = caster.name if is_instance_valid(caster) else "Unknown"

	var arrow = Area3D.new()
	arrow.name = "Arrow"
	# Tạo mesh hình mũi tên (cylinder dài)
	var mesh = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 0.05
	cyl.bottom_radius = 0.15
	cyl.height = 1.5
	mesh.mesh = cyl

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.8, 0.2)  # xanh lá
	mat.emission_enabled = true
	mat.emission = Color(0.1, 0.5, 0.1)
	mesh.material_override = mat
	arrow.add_child(mesh)

	# Collision shape (cylinder)
	var col = CollisionShape3D.new()
	var shape = CylinderShape3D.new()
	shape.radius = 0.2
	shape.height = 1.5
	col.shape = shape
	arrow.add_child(col)

	# Thiết lập thuộc tính
	arrow.set_meta("damage", data.damage)
	arrow.set_meta("target", locked_target)

	# Xử lý va chạm
	arrow.body_entered.connect(_on_arrow_hit.bind(arrow))

	# Thêm vào scene
	GameManagerGlobal.get_tree().current_scene.add_child(arrow)

	# Đặt vị trí & hướng tại caster, quay về target_pos
	arrow.global_transform.origin = caster.global_transform.origin + Vector3(0, 1, 0)
	arrow.look_at(target_pos + Vector3(0, 1, 0), Vector3.UP)
	# Cylinder mặc định nằm dọc Y, xoay 90° quanh X để nằm ngang
	arrow.rotate_object_local(Vector3.RIGHT, deg_to_rad(90))

	_arrow_instance = arrow

	# Bay đến target
	var start_pos = arrow.global_transform.origin
	var end_pos = target_pos + Vector3(0, 1, 0)
	var total_dist = (end_pos - start_pos).length()
	var t: float = 0.0

	while t < 1.0 and is_instance_valid(arrow):
		var prev_origin = arrow.global_transform.origin
		t += (data.speed * 0.016) / maxf(total_dist, 0.1)
		t = minf(t, 1.0)
		arrow.global_transform.origin = start_pos.lerp(end_pos, t)
		# Quay đầu mũi tên theo hướng bay
		if arrow.global_transform.origin.distance_to(prev_origin) > 0.001:
			var vel = (arrow.global_transform.origin - prev_origin).normalized()
			if vel.length() > 0.001:
				arrow.look_at(arrow.global_transform.origin + vel, Vector3.UP)
				arrow.rotate_object_local(Vector3.RIGHT, deg_to_rad(90))

		await arrow.get_tree().process_frame

	if is_instance_valid(arrow):
		arrow.queue_free()

	print("Arrow hit by:", caster_name, "→ damage:", data.damage)

func _on_arrow_hit(body: Node, arrow: Area3D) -> void:
	var dmg: int = arrow.get_meta("damage")
	var locked: Node = arrow.get_meta("target")

	# Chỉ gây damage khi trúng target đã lock
	if body == locked:
		if body.has_method("take_damage"):
			body.take_damage(dmg)
		if is_instance_valid(arrow):
			arrow.queue_free()
