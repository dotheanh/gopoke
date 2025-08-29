# monster_skill_caster.gd
extends Node
class_name MonsterSkillCaster

var SkillBaseClass = preload("res://skills/scripts/skill_base.gd")

@export var skill_resources: Array[SkillData]  # array các file SkillData .tres
var skill_instances: Array[SkillBase] = []
var can_cast: bool = true
var caster: Node3D

func _ready():
	# tạo instance skill từ SkillData
	for data in skill_resources:
		var skill_class: Script = load("res://skills/scripts/%s.gd" % data.skill_name)
		var skill_inst = skill_class.new()
		skill_inst.data = data
		skill_inst.caster = caster
		skill_instances.append(skill_inst)

func cast(skill: SkillBase, target_pos: Vector3) -> void:
	if not can_cast: return
	can_cast = false
	skill.caster = caster
	await skill.cast(target_pos)
	can_cast = true
