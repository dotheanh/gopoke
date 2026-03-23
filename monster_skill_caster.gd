# monster_skill_caster.gd
# Quản lý việc khởi tạo và cast skill cho Monster.
# Mỗi Monster có một array SkillData được gán từ inspector.
# ─────────────────────────────────────────────────────────
# CÁCH DÙNG:
#   1. Tạo các file .tres SkillData trong res://configs/
#   2. Kéo thả các .tres vào @export var skills trong inspector
#   3. Script skill phải extends SkillBase và đặt trong res://skills/scripts/
# ─────────────────────────────────────────────────────────
extends Node
class_name MonsterSkillCaster

# ── Skill Registry ──────────────────────────────────────
const SKILL_REGISTRY: Dictionary = {
	"Meteor": preload("res://skills/scripts/Meteor.gd"),
	"Quake":  preload("res://skills/scripts/Quake.gd"),
	# Thêm skill mới ở đây:
	# "Arrow": preload("res://skills/scripts/Arrow.gd"),
	# "Dash":  preload("res://skills/scripts/Dash.gd"),
	# "Slash": preload("res://skills/scripts/Slash.gd"),
}

# ── Exported (kéo thả SkillData .tres vào đây) ─────────
@export var skills: Array[SkillData] = []

# ── Runtime state ───────────────────────────────────────
var _skill_instances: Array[SkillBase] = []
var _can_cast: bool = true
var _caster: Node3D

var caster: Node3D:
	get: return _caster
	set(v):
		_caster = v
		_build_skill_instances()

# ─────────────────────────────────────────────────────────
func _build_skill_instances() -> void:
	_skill_instances.clear()
	for data in skills:
		var script_class = SKILL_REGISTRY.get(data.skill_name)
		if script_class == null:
			push_error("MonsterSkillCaster: Unknown skill '%s'. Add it to SKILL_REGISTRY." % data.skill_name)
			continue
		var inst: SkillBase = script_class.new()
		inst.data = data
		inst.caster = _caster
		_skill_instances.append(inst)

# ─────────────────────────────────────────────────────────
func cast(skill: SkillBase, target_pos: Vector3) -> void:
	if not _can_cast:
		return
	_can_cast = false
	skill.caster = _caster
	await skill.cast(target_pos)
	_can_cast = true

# ─────────────────────────────────────────────────────────
func cast_random(player_pos: Vector3) -> void:
	if _skill_instances.is_empty():
		return
	var skill = _skill_instances[randi() % _skill_instances.size()]
	cast(skill, player_pos)
