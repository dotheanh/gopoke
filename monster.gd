# monster.gd
extends CharacterBody3D
class_name Monster

@export var anim_player: AnimationPlayer

@export var max_hp: int = 100
@export var delay_start: float = 1.0
@export var rotation_speed: float = 5.0 # radians/sec

var hp: int
@onready var skill_caster: MonsterSkillCaster = $MonsterSkillCaster

var _target_yaw: float = 0.0
var _pending_skill = null
var _pending_cast_pos: Vector3 = Vector3.ZERO

const PI = 3.141592653589793
const TAU = PI * 2.0

func _ready():
	anim_player.play("Idle")
	hp = max_hp
	await Engine.get_main_loop().create_timer(delay_start).timeout
	skill_caster.caster = self
	if not skill_caster.skill_instances.is_empty():
		auto_cast()

func take_damage(amount: int) -> void:
	hp -= amount
	if hp <= 0:
		die()

func die():
	print(name, "died")
	queue_free()

func auto_cast() -> void:
	await get_tree().process_frame   # ✅ KHÔNG có ()
	while hp > 0:
		if skill_caster.can_cast and not skill_caster.skill_instances.is_empty():
			var skill = skill_caster.skill_instances[randi() % skill_caster.skill_instances.size()]
			var player = GameManagerGlobal.player
			if player:
				var dir = player.global_transform.origin - global_transform.origin
				dir.y = 0
				if dir.length() > 0.001:
					dir = dir.normalized()
					_target_yaw = atan2(-dir.x, -dir.z)  # ✅ công thức yaw đúng
					_pending_skill = skill
					_pending_cast_pos = player.global_transform.origin
		await get_tree().process_frame   # ✅ KHÔNG có ()

func _physics_process(delta: float) -> void:
	if _pending_skill != null:
		var diff = _short_angle_diff(rotation.y, _target_yaw)
		var max_step = rotation_speed * delta
		var step = clamp(diff, -max_step, max_step)
		rotation.y += step

		if abs(_short_angle_diff(rotation.y, _target_yaw)) < 0.02:
			rotation.y = _target_yaw
			if GameManagerGlobal.player:
				_pending_cast_pos = GameManagerGlobal.player.global_transform.origin
			skill_caster.cast(_pending_skill, _pending_cast_pos)
			_pending_skill = null

func _short_angle_diff(from_angle: float, to_angle: float) -> float:
	var d = to_angle - from_angle
	while d > PI:
		d -= TAU
	while d < -PI:
		d += TAU
	return d
