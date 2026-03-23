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
@onready var hp_bar_fill: MeshInstance3D = $HPBarFill
@onready var hp_bar_bg: MeshInstance3D = $HPBarBg

## AnimationPlayer nằm trong scene con đã instance (VD: megaswampert2/AnimationPlayer)
## Dùng find_child thay vì @export để tránh NodePath resolution order issue
var anim_player: AnimationPlayer

## Tên scene con chứa model (đặt trong Inspector hoặc override ở subclass)
@export var model_scene_name: String = ""

## HP bar — separate name label + HP number label
## Name label: bên trên thanh máu (null nếu node không tồn tại — Boss không có)
var hp_name_label: Label3D
## HP number label: bên trong thanh máu
var hp_num_label: Label3D

# ── AI state ────────────────────────────────────────────────────
var _target_yaw: float = 0.0
var _pending_skill: SkillBase = null
var _pending_cast_pos: Vector3 = Vector3.ZERO
var _facing_timer: float = 0.0
var _ai_active: bool = true
var _hp_overridden: bool = false

# ── Config cho AI (đọc từ config hoặc default) ─────────────────
var _face_update_interval: float = 0.8

# ── HP bar state ────────────────────────────────────────────────
var _bar_max_size: float = 2.0   # kích thước x ban đầu của BoxMesh fill

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

	# Lấy HP bar labels — có thể null (Boss không có 3D labels)
	hp_name_label = get_node_or_null("HPNameLabel")
	hp_num_label = get_node_or_null("HPNumLabel")

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
	# Boss có thể override max_hp trước _ready → không ghi đè
	if not _hp_overridden:
		max_hp = config.max_hp
		hp = max_hp
	_rotation_speed = config.rotation_speed
	_idle_animation = config.idle_animation
	if "face_update_interval" in config:
		_face_update_interval = config.get("face_update_interval")
	if anim_player != null and anim_player.has_animation(_idle_animation):
		anim_player.play(_idle_animation)

	# ── HP bar labels — separate name vs HP number ──────────────────
	var display: String = config.display_name if "display_name" in config else str(name)

	if hp_name_label != null:
		hp_name_label.text = display
		hp_name_label.modulate = Color(1, 1, 1, 1)

	if hp_num_label != null:
		hp_num_label.text = "%d/%d" % [hp, max_hp]
		hp_num_label.modulate = Color(1, 1, 1, 1)

	# Lưu kích thước BoxMesh fill để scale đúng
	if hp_bar_fill != null and hp_bar_fill.mesh is BoxMesh:
		_bar_max_size = (hp_bar_fill.mesh as BoxMesh).size.x
		hp_changed.connect(_on_hp_bar_update)

func _apply_defaults() -> void:
	max_hp = 100
	hp = max_hp
	_rotation_speed = 5.0
	_idle_animation = "Idle"
	if anim_player != null and anim_player.has_animation(_idle_animation):
		anim_player.play(_idle_animation)
	if hp_bar_fill != null and hp_bar_fill.mesh is BoxMesh:
		_bar_max_size = (hp_bar_fill.mesh as BoxMesh).size.x
		hp_changed.connect(_on_hp_bar_update)

# ─────────────────────────────────────────────────────────────────
func take_damage(amount: int) -> void:
	hp = max(0, hp - amount)
	emit_signal("hp_changed", hp, max_hp)
	if hp == 0:
		die()

func die() -> void:
	_ai_active = false
	_pending_skill = null

	# Xóa HP bar
	if hp_name_label != null:
		hp_name_label.queue_free()
	if hp_num_label != null:
		hp_num_label.queue_free()
	if hp_bar_fill != null:
		hp_bar_fill.queue_free()
	if hp_bar_bg != null:
		hp_bar_bg.queue_free()

	# Scale animation để tạo hiệu ứng biến mất
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector3.ZERO, 0.4)\
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "modulate:a", 0.0, 0.3)\
		.set_ease(Tween.EASE_IN)

	await tween.finished
	emit_signal("died")
	queue_free()

# ─────────────────────────────────────────────────────────────────
func _start_ai_loop() -> void:
	while _ai_active and hp > 0:
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

## Màu HP bar theo tỷ lệ
func _hp_color_ratio(ratio: float) -> Color:
	if ratio > 0.5:
		return Color(0.2, 1.0, 0.2)   # xanh
	elif ratio > 0.25:
		return Color(1.0, 0.8, 0.0)   # vàng
	else:
		return Color(1.0, 0.2, 0.2)   # đỏ

## Cập nhật HP bar mesh khi HP thay đổi
func _on_hp_bar_update(current: int, max_val: int) -> void:
	var ratio := float(current) / float(max_val) if max_val > 0 else 0.0

	# Đặt size.x của BoxMesh fill trực tiếp (co lại từ phải sang trái)
	if hp_bar_fill != null and hp_bar_fill.mesh is BoxMesh:
		var box: BoxMesh = hp_bar_fill.mesh as BoxMesh
		box.size.x = maxf(ratio * _bar_max_size, 0.01)
		if hp_bar_fill.material_override == null:
			hp_bar_fill.material_override = StandardMaterial3D.new()
		hp_bar_fill.material_override.albedo_color = _hp_color_ratio(ratio)

	# Cập nhật separate labels: name + HP number
	var display: String = config.display_name if config and "display_name" in config else str(name)
	if hp_name_label != null:
		hp_name_label.text = display
	if hp_num_label != null:
		hp_num_label.text = "%d/%d" % [current, max_val]

## Setup hướng nhắm — gọi từ bên ngoài khi muốn ép skill cụ thể
func aim_at(target_pos: Vector3, skill: SkillBase) -> void:
	_update_face_target(target_pos)
	_pending_skill = skill
	_pending_cast_pos = target_pos
