# monster.gd
# Base script cho tất cả enemy (Monster và Boss đều dùng chung script này).
# Mọi thông số được đọc từ @export var config: MonsterConfig.
# ───────────────────────────────────────────────────────────────────
# CÁCH TẠO MONSTER MỚI:
#   1. Tạo file .tres MonsterConfig trong res://configs/
#   2. Gán config vào @export var config trong Inspector
#   3. Gán SkillData .tres vào config.skills[]
# ───────────────────────────────────────────────────────────────────
extends CharacterBody3D
class_name Monster

# ── Config (kéo thả MonsterConfig .tres vào Inspector) ─────────────
@export var config: MonsterConfig

# ── Runtime stats (đọc từ config) ───────────────────────────────
var max_hp: int = 100
var hp: int = 100
var _rotation_speed: float = 5.0
var _idle_animation: String = "Idle"

# ── Nodes ────────────────────────────────────────────────────────
@onready var skill_caster: MonsterSkillCaster = $MonsterSkillCaster

## AnimationPlayer nằm trong scene con đã instance (VD: megaswampert2/AnimationPlayer)
## Dùng find_child thay vì @export để tránh NodePath resolution order issue
var anim_player: AnimationPlayer

## Tên scene con chứa model (đặt trong Inspector hoặc override ở subclass)
@export var model_scene_name: String = ""

# ── AI state ────────────────────────────────────────────────────
var _target_yaw: float = 0.0
var _pending_skill: SkillBase = null
var _pending_cast_pos: Vector3 = Vector3.ZERO
var _facing_timer: float = 0.0

# ── Config cho AI (đọc từ config hoặc default) ─────────────────
var _face_update_interval: float = 0.8

# ── Signals ──────────────────────────────────────────────────────
signal hp_changed(current: int, max_hp: int)
signal died

const PI = 3.141592653589793
const TAU = PI * 2.0

## Tìm AnimationPlayer bên trong scene con đã được instance
## Thử theo thứ tự: model_scene_name -> tên thường gặp -> find_child đệ quy
func _find_animation_player() -> AnimationPlayer:
	# 1. Nếu có model_scene_name, tìm con trực tiếp
	if model_scene_name != "" and has_node(model_scene_name):
		var model = get_node(model_scene_name)
		if model.has_node("AnimationPlayer"):
			return model.get_node("AnimationPlayer")

	# 2. Thử các tên model phổ biến (theo thứ tự ưu tiên)
	var common_model_names = ["megaswampert2", "rayquaza3d", "megasceptile2", "megasceptile"]
	for model_nm in common_model_names:
		if has_node(model_nm) and get_node(model_nm).has_node("AnimationPlayer"):
			return get_node(model_nm).get_node("AnimationPlayer")

	# 3. Tìm đệ quy bất kỳ AnimationPlayer nào trong cây con
	var found := find_child("AnimationPlayer", true, false)
	if found is AnimationPlayer:
		return found

	# 4. Thử find_child không giới hạn độ sâu
	var deep := find_child("AnimationPlayer", false, false)
	if deep is AnimationPlayer:
		return deep

	return null

func _ready():
	# Tìm AnimationPlayer trong scene con SAU khi scene đã được setup đầy đủ
	anim_player = _find_animation_player()

	if config != null:
		_apply_config()
	else:
		_apply_defaults()

	skill_caster.caster = self

	var delay = config.delay_before_first_cast if config else 1.0
	await get_tree().create_timer(delay).timeout

	if not skill_caster._skill_instances.is_empty():
		_start_ai_loop()

# ─────────────────────────────────────────────────────────────────
func _apply_config() -> void:
	max_hp = config.max_hp
	hp = max_hp
	_rotation_speed = config.rotation_speed
	_idle_animation = config.idle_animation
	if "face_update_interval" in config:
		_face_update_interval = config.get("face_update_interval")
	if anim_player != null and anim_player.has_animation(_idle_animation):
		anim_player.play(_idle_animation)

func _apply_defaults() -> void:
	max_hp = 100
	hp = max_hp
	_rotation_speed = 5.0
	_idle_animation = "Idle"
	if anim_player != null and anim_player.has_animation(_idle_animation):
		anim_player.play(_idle_animation)

# ─────────────────────────────────────────────────────────────────
func take_damage(amount: int) -> void:
	hp = max(0, hp - amount)
	emit_signal("hp_changed", hp, max_hp)
	if hp == 0:
		die()

func die() -> void:
	emit_signal("died")
	queue_free()

# ─────────────────────────────────────────────────────────────────
func _start_ai_loop() -> void:
	while hp > 0:
		await get_tree().process_frame
		skill_caster.cast_random(_get_player_pos())

func _get_player_pos() -> Vector3:
	var player = GameManagerGlobal.player
	return player.global_transform.origin if player else Vector3.ZERO

# ─────────────────────────────────────────────────────────────────
func _physics_process(delta: float) -> void:
	# ── Face tracking player liên tục ────────────────────────────
	if _pending_skill == null:
		_facing_timer += delta
		if _facing_timer >= _face_update_interval:
			_facing_timer = 0.0
			_update_face_target(_get_player_pos())
		# Quay mượt về hướng player
		_smooth_rotate(delta)

	# ── Đợi quay đủ góc rồi cast skill ───────────────────────
	else:
		_smooth_rotate(delta)
		if abs(_short_angle_diff(rotation.y, _target_yaw)) < 0.02:
			rotation.y = _target_yaw
			skill_caster.cast(_pending_skill, _pending_cast_pos)
			_pending_skill = null

## Quay mượt từ góc hiện tại → _target_yaw
func _smooth_rotate(delta: float) -> void:
	var diff = _short_angle_diff(rotation.y, _target_yaw)
	var max_step = _rotation_speed * delta
	rotation.y += clamp(diff, -max_step, max_step)

## Cập nhật _target_yaw để hướng về một vị trí (player hoặc cast target)
func _update_face_target(pos: Vector3) -> void:
	var dir = pos - global_transform.origin
	dir.y = 0
	if dir.length() > 0.001:
		_target_yaw = atan2(-dir.x, -dir.z)

func _short_angle_diff(from_angle: float, to_angle: float) -> float:
	var d = to_angle - from_angle
	while d > PI:  d -= TAU
	while d < -PI: d += TAU
	return d

## Setup hướng nhắm — gọi từ bên ngoài khi muốn ép skill cụ thể
func aim_at(target_pos: Vector3, skill: SkillBase) -> void:
	_update_face_target(target_pos)
	_pending_skill = skill
	_pending_cast_pos = target_pos
