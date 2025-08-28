# monster_skill_caster.gd
extends Node
class_name MonsterSkillCaster

@export var skills: Array[SkillData]
var can_cast := true

func cast(skill: SkillData, target_pos: Vector3):
	if not can_cast:
		return
	can_cast = false
	
	# Hiện vùng báo hiệu
	var indicator := AreaIndicator.new()
	indicator.setup(skill.shape, skill.size)
	get_tree().current_scene.add_child(indicator)

	# Chỉ đặt y = 0, để indicator nằm trên mặt đất
	indicator.global_transform.origin = Vector3(target_pos.x, 0, target_pos.z)

	await get_tree().create_timer(skill.cast_time).timeout

	# Gây damage / spawn projectile tuỳ loại skill
	print("Skill", skill.skill_name, "hit at", indicator.global_transform.origin)

	indicator.queue_free()

	# Hồi chiêu
	await get_tree().create_timer(skill.cooldown).timeout
	can_cast = true
