# monster_skill_caster.gd
extends Node
class_name MonsterSkillCaster

@export var skills: Array[SkillData]

var can_cast := true

func cast(skill: SkillData, target_pos: Vector3):
	if not can_cast:
		return
	can_cast = false

	# Indicator luôn ở mặt đất
	var indicator := AreaIndicator.new()
	indicator.setup(skill.shape, skill.size)
	get_tree().current_scene.add_child(indicator)
	indicator.global_transform.origin = Vector3(target_pos.x, 0, target_pos.z)
	
	await get_tree().create_timer(skill.cast_time).timeout

	# Gọi hàm riêng cho từng skill
	match skill.skill_name:
		"Slash":
			_cast_slash(skill, target_pos)
		"FanSlash":
			_cast_fan_slash(skill, target_pos)
		"Meteor":
			_cast_meteor(skill, target_pos)
		"Quake":
			_cast_quake(skill, target_pos)
		_:
			print("Unknown skill:", skill.skill_name)

	indicator.queue_free()

	# Hồi chiêu
	await get_tree().create_timer(skill.cooldown).timeout
	can_cast = true

# --- Các skill riêng biệt ---
func _cast_slash(skill: SkillData, target_pos: Vector3) -> void:
	if GameManagerGlobal.player:
		var player_pos = GameManagerGlobal.player.global_transform.origin
		var dist = (Vector3(player_pos.x, 0, player_pos.z) - Vector3(target_pos.x, 0, target_pos.z)).length()
		if dist <= skill.effect_range:
			GameManagerGlobal.player.take_damage(skill.damage)
			print("Player hit by Slash for", skill.damage)

func _cast_fan_slash(skill: SkillData, target_pos: Vector3) -> void:
	# logic tương tự Slash nhưng với góc quạt
	pass

func _cast_meteor(skill: SkillData, target_pos: Vector3) -> void:
	# Tạo meteor mesh
	var meteor = MeshInstance3D.new()
	meteor.mesh = SphereMesh.new()
	meteor.scale = Vector3(0.5, 0.5, 0.5)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1, 0.5, 0)
	meteor.material_override = mat
	get_tree().current_scene.add_child(meteor)

	# Lấy vị trí Monster đang cast
	if not owner:
		print("Meteor has no owner!")
		return
	else:
		print("Meteor cast by:", owner.name)

	var start_pos = owner.global_transform.origin + Vector3(0, 5, 0)  # luôn trên đầu Monster
	var end_pos = Vector3(target_pos.x, 0, target_pos.z)
	meteor.global_transform.origin = start_pos

	# Thời gian bay
	var travel_time = skill.effect_range / skill.speed
	var t := 0.0

	while t < 1.0:
		await get_tree().process_frame
		t += get_process_delta_time() / travel_time
		meteor.global_transform.origin = start_pos.lerp(end_pos, t)

	# Kiểm tra va chạm với Player
	if GameManagerGlobal.player:
		var player_pos = GameManagerGlobal.player.global_transform.origin
		var dist = (Vector3(player_pos.x, 0, player_pos.z) - end_pos).length()
		if dist <= skill.size.x:
			GameManagerGlobal.player.take_damage(skill.damage)
			print("Player hit by Meteor for", skill.damage)

	# Xoá meteor sau khi hạ xuống
	meteor.queue_free()


func _cast_quake(skill: SkillData, target_pos: Vector3) -> void:
	# Dậm đất, damage tất cả trong bán kính skill.effect_range
	if GameManagerGlobal.player:
		var player_pos = GameManagerGlobal.player.global_transform.origin
		var dist = (Vector3(player_pos.x, 0, player_pos.z) - Vector3(target_pos.x, 0, target_pos.z)).length()
		if dist <= skill.effect_range:
			GameManagerGlobal.player.take_damage(skill.damage)
			print("Player hit by Quake for", skill.damage)
