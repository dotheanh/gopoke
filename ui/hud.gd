extends CanvasLayer
class_name HUD

# Chỉ cần kéo thả trực tiếp từ editor
@export var hp_bar: ProgressBar

var player: Node = null
var _attack_btn: Button

func bind_player(p):
	player = p
	print("Init hp:", player.hp, player.max_hp)

	# Nếu player có signal, connect
	if player.has_signal("hp_changed") and not player.hp_changed.is_connected(self._on_player_hp_changed):
		player.hp_changed.connect(self._on_player_hp_changed)

	# Set ngay max & current HP
	if hp_bar:
		hp_bar.max_value = player.max_hp
		hp_bar.value = player.hp
	else:
		push_warning("HUD: hp_bar not assigned in inspector!")

func _ready() -> void:
	_build_attack_button()

func _build_attack_button() -> void:
	# Nút Attack — góc dưới phải màn hình
	_attack_btn = Button.new()
	_attack_btn.text = "⚔ ATK"
	_attack_btn.custom_minimum_size = Vector2(100, 60)

	# Style cho nút
	var style_normal := StyleBoxFlat.new()
	style_normal.bg_color = Color(0.8, 0.15, 0.15, 0.85)
	style_normal.set_corner_radius_all(12)
	style_normal.content_margin_left = 10
	style_normal.content_margin_right = 10
	style_normal.content_margin_top = 8
	style_normal.content_margin_bottom = 8
	_attack_btn.add_theme_stylebox_override("normal", style_normal)

	var style_pressed := StyleBoxFlat.new()
	style_pressed.bg_color = Color(1.0, 0.3, 0.3, 0.95)
	style_pressed.set_corner_radius_all(12)
	style_pressed.content_margin_left = 10
	style_pressed.content_margin_right = 10
	style_pressed.content_margin_top = 8
	style_pressed.content_margin_bottom = 8
	_attack_btn.add_theme_stylebox_override("pressed", style_pressed)

	var style_hover := StyleBoxFlat.new()
	style_hover.bg_color = Color(0.9, 0.2, 0.2, 0.9)
	style_hover.set_corner_radius_all(12)
	style_hover.content_margin_left = 10
	style_hover.content_margin_right = 10
	style_hover.content_margin_top = 8
	style_hover.content_margin_bottom = 8
	_attack_btn.add_theme_stylebox_override("hover", style_hover)

	_attack_btn.add_theme_font_size_override("font_size", 22)
	_attack_btn.add_theme_color_override("font_color", Color.WHITE)

	# Anchor góc dưới phải
	_attack_btn.set_anchor(SIDE_LEFT,   1.0)
	_attack_btn.set_anchor(SIDE_RIGHT,  1.0)
	_attack_btn.set_anchor(SIDE_TOP,    1.0)
	_attack_btn.set_anchor(SIDE_BOTTOM, 1.0)
	_attack_btn.offset_left   = -130
	_attack_btn.offset_right  = -20
	_attack_btn.offset_top    = -80
	_attack_btn.offset_bottom = -15

	_attack_btn.pressed.connect(_on_attack_pressed)
	add_child(_attack_btn)

func _on_attack_pressed() -> void:
	if player and player.has_method("_cast_arrow"):
		player._cast_arrow()
	else:
		print("HUD: No player or player has no _cast_arrow()")

func _on_player_hp_changed(hp: int, max_hp: int) -> void:
	if hp_bar:
		hp_bar.max_value = max_hp
		hp_bar.value = hp
