# monster.gd
extends CharacterBody3D
class_name Monster

@export var max_hp: int = 100
var hp: int
var delay_start: float = 1

@onready var skill_caster: MonsterSkillCaster = $MonsterSkillCaster

func _ready():
	hp = max_hp
	
	await Engine.get_main_loop().create_timer(delay_start).timeout
	
	# gán owner cho skill_caster
	skill_caster.caster = self
	
	# bắt đầu AI cast skill
	if not skill_caster.skill_instances.is_empty():
		auto_cast()

func take_damage(amount: int) -> void:
	hp -= amount
	if hp <= 0:
		die()

func die():
	print(name, "died")
	queue_free()

# chọn random skill để cast
func auto_cast():
	await get_tree().process_frame
	while hp > 0:
		if skill_caster.can_cast and not skill_caster.skill_instances.is_empty():
			var skill = skill_caster.skill_instances[randi() % skill_caster.skill_instances.size()]
			var player = GameManagerGlobal.player
			if player:
				skill_caster.cast(skill, player.global_transform.origin)
		await get_tree().process_frame
