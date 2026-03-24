# meteor_skill.gd

extends SkillBase
class_name MeteorSkill

func execute(target_pos: Vector3) -> void:
	# Kiểm tra caster còn tồn tại
	if caster == null or not is_instance_valid(caster):
		return

	var meteor = Projectile.new()
	meteor.speed = data.speed
	meteor.damage = data.damage
	meteor.radius = data.size.x
	meteor.target_pos = Vector3(target_pos.x, 0, target_pos.z)
	meteor.caster = caster

	# Add vào scene TRƯỚC khi set global_transform
	GameManagerGlobal.get_tree().current_scene.add_child(meteor)
	meteor.global_transform.origin = caster.global_transform.origin + Vector3(0, 5, 0)
	meteor._update_mesh_scale()
	print("Meteor cast by:", caster.name)
