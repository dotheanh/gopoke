# monster_skill_caster.gd
extends Node
class_name MonsterSkillCaster

@export var skills: Array[SkillData]
var can_cast := true

func cast(skill: SkillData, target_pos: Vector3):
	if not can_cast: return
	can_cast = false

	# Indicator trên mặt đất
	var indicator := AreaIndicator.new()
	indicator.setup(skill.shape, skill.size)
	get_tree().current_scene.add_child(indicator)
	indicator.global_transform.origin = Vector3(target_pos.x, 0, target_pos.z)
	
	await get_tree().create_timer(skill.cast_time).timeout

	# Gọi skill riêng
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
	await get_tree().create_timer(skill.cooldown).timeout
	can_cast = true

# --- Các skill riêng ---
func _cast_slash(skill: SkillData, target_pos: Vector3) -> void:
	if GameManagerGlobal.player:
		var player_pos = GameManagerGlobal.player.global_transform.origin
		var dist = (Vector3(player_pos.x, 0, player_pos.z) - Vector3(target_pos.x, 0, target_pos.z)).length()
		if dist <= skill.effect_range:
			GameManagerGlobal.player.take_damage(skill.damage)
			print("Player hit by Slash for", skill.damage)

func _cast_fan_slash(skill: SkillData, target_pos: Vector3) -> void:
	# Giả lập quạt bằng 1 projectile (có thể spawn nhiều projectiles theo góc)
	if GameManagerGlobal.player:
		var player_pos = GameManagerGlobal.player.global_transform.origin
		var dir = (player_pos - owner.global_transform.origin).normalized()
		var angle_to_player = dir.angle_to((target_pos - owner.global_transform.origin).normalized())
		if angle_to_player <= deg_to_rad(skill.effect_range):
			GameManagerGlobal.player.take_damage(skill.damage)
			print("Player hit by FanSlash for", skill.damage)

func _cast_meteor(skill: SkillData, target_pos: Vector3) -> void:
	var meteor = Projectile.new()
	meteor.speed = skill.speed
	meteor.damage = skill.damage
	meteor.radius = skill.size.x          # set bán kính va chạm
	meteor.target_pos = Vector3(target_pos.x, 0, target_pos.z)
	meteor.owner = owner

	# Xuất phát trên đầu Monster
	meteor.global_transform.origin = owner.global_transform.origin + Vector3(0, 5, 0)

	# Cập nhật scale mesh theo radius
	meteor._update_mesh_scale()

	get_tree().current_scene.add_child(meteor)
	print("Meteor cast by:", owner.name)



func _cast_quake(skill: SkillData, target_pos: Vector3) -> void:
	# Damage quanh target
	if GameManagerGlobal.player:
		var player_pos = GameManagerGlobal.player.global_transform.origin
		var dist = (Vector3(player_pos.x, 0, player_pos.z) - Vector3(target_pos.x, 0, target_pos.z)).length()
		if dist <= skill.effect_range:
			GameManagerGlobal.player.take_damage(skill.damage)
			print("Player hit by Quake for", skill.damage)
