# quake_skill.gd

extends SkillBase
class_name QuakeSkill

var SkillBaseClass = preload("res://skills/scripts/skill_base.gd")

# Indicator luôn nằm tại caster
func get_indicator_position(target_pos: Vector3) -> Vector3:
	return Vector3(caster.global_transform.origin.x, 0, caster.global_transform.origin.z)

func execute(target_pos: Vector3) -> void:
	if GameManagerGlobal.player:
		var player_pos = GameManagerGlobal.player.global_transform.origin
		var dist = (Vector3(player_pos.x,0,player_pos.z) - get_indicator_position(target_pos)).length()
		if dist <= data.effect_range:
			GameManagerGlobal.player.take_damage(data.damage)
			print("Player hit by Quake for", data.damage)
