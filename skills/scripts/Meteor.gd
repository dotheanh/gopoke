# meteor_skill.gd

extends SkillBase
class_name MeteorSkill

var SkillBaseClass = preload("res://skills/scripts/skill_base.gd")

func execute(target_pos: Vector3) -> void:
	var meteor = Projectile.new()
	meteor.speed = data.speed
	meteor.damage = data.damage
	meteor.radius = data.size.x
	meteor.target_pos = Vector3(target_pos.x, 0, target_pos.z)
	meteor.caster = caster
	
	# xuất phát trên đầu Monster
	meteor.global_transform.origin = caster.global_transform.origin + Vector3(0,5,0)
	meteor._update_mesh_scale()
	GameManagerGlobal.get_tree().current_scene.add_child(meteor)
	print("Meteor cast by:", caster.name)
