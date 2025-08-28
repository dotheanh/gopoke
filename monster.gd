extends CharacterBody3D
class_name Monster

@export var max_hp: int = 100
var hp: int

@onready var skill_caster: MonsterSkillCaster = $MonsterSkillCaster

func _ready():
	hp = max_hp
	
	# bắt đầu AI cast skill
	if not skill_caster.skills.is_empty():
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
		if skill_caster.can_cast and not skill_caster.skills.is_empty():
			var skill = skill_caster.skills[randi() % skill_caster.skills.size()]
			# target giả định: Player (có thể set qua global singleton GameManager)
			var player = get_tree().get_first_node_in_group("Player")
			if player:
				skill_caster.cast(skill, player.global_transform.origin)
		await get_tree().process_frame
