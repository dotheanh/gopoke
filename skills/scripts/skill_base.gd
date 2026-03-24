# skill_base.gd
extends Node
class_name SkillBase

@export var data: SkillData
var caster: Node3D

# Entry point để cast skill
func cast(target_pos: Vector3) -> void:
	# Kiểm tra caster còn tồn tại
	if caster == null or not is_instance_valid(caster):
		return
	await show_indicator(target_pos)
	execute(target_pos)
	await Engine.get_main_loop().create_timer(data.cooldown).timeout

# Hiển thị Indicator
func show_indicator(target_pos: Vector3):
	var indicator = AreaIndicator.new()
	indicator.setup(data.shape, data.size)
	var current_scene = GameManagerGlobal.get_tree().get_current_scene()
	current_scene.add_child(indicator)
	indicator.global_transform.origin = get_indicator_position(target_pos)
	await Engine.get_main_loop().create_timer(data.cast_time).timeout
	indicator.queue_free()

# Override để thay đổi vị trí indicator (VD: Quake ở caster)
func get_indicator_position(target_pos: Vector3) -> Vector3:
	return target_pos

# Override ở subclass để thực thi skill
func execute(_target_pos: Vector3) -> void:
	pass
