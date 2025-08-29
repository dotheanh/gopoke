# skill_base.gd
extends Node
class_name SkillBase

@export var data: SkillData
var caster: Node3D

# Entry point để cast skill
func cast(target_pos: Vector3) -> void:
	# 1. show indicator
	await show_indicator(caster, target_pos)
	
	# 2. chờ cast_time
	await Engine.get_main_loop().create_timer(data.cast_time).timeout
	
	# 3. thi triển skill
	execute(target_pos)

# Hiển thị Indicator (có thể override để thay đổi vị trí)
func show_indicator(parent: Node3D, target_pos: Vector3):
	var indicator = AreaIndicator.new()
	indicator.setup(data.shape, data.size)
	var current_scene = GameManagerGlobal.get_tree().get_current_scene()
	current_scene.add_child(indicator)
	indicator.global_transform.origin = get_indicator_position(target_pos)
	await Engine.get_main_loop().create_timer(data.cast_time).timeout
	indicator.queue_free()

# Có thể override để thay đổi vị trí indicator (ví dụ Quake cast ở caster)
func get_indicator_position(target_pos: Vector3) -> Vector3:
	return target_pos

# Thực thi skill (override ở subclass)
func execute(target_pos: Vector3) -> void:
	pass
