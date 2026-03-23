# monster_hp_bar.gd
# Attach vào Label3D con của Monster/Boss để hiển thị HP.
# Tự động cập nhật khi nhận signal hp_changed.

class_name MonsterHpBar
extends Label3D

var _target: Node
var _current_hp: int = 0
var _max_hp: int = 100

func setup(target: Node) -> void:
	_target = target
	_max_hp = target.max_hp
	_current_hp = _max_hp
	_text = "%s: %d/%d" % [_target.name, _current_hp, _max_hp]
	_modulate = Color.WHITE

	# Bind signal
	if _target.has_signal("hp_changed") and not _target.hp_changed.is_connected(_on_hp_changed):
		_target.hp_changed.connect(_on_hp_changed)

	if _target.has_signal("died"):
		_target.died.connect(_on_died)

func _on_hp_changed(current: int, max_hp: int) -> void:
	_current_hp = current
	_max_hp = max_hp
	_text = "%s: %d/%d" % [_target.name, _current_hp, _max_hp]

	# Đỏ dần khi HP thấp
	var ratio := float(_current_hp) / float(max_hp) if max_hp > 0 else 0.0
	if ratio > 0.5:
		_modulate = Color.GREEN
	elif ratio > 0.25:
		_modulate = Color.YELLOW
	else:
		_modulate = Color.RED

func _on_died() -> void:
	if is_instance_valid(self):
		queue_free()
