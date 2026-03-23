# boss_hp_bar.gd
# CanvasLayer UI cho Boss HP bar — fixed ở giữa trên màn hình.
# Tên Pokémon nằm trên thanh máu, số HP overlay trong bar.
# ─────────────────────────────────────────────────────────────────
extends CanvasLayer

const BAR_HEIGHT := 32.0
const MARGIN_TOP := 18.0
const BAR_SCREEN_RATIO := 0.85   # chiếm 85% chiều ngang màn hình

var _bar_fill:  ColorRect
var _name_label: Label
var _hp_label:  Label

func _ready() -> void:
	_build_ui()
	var boss = get_parent()
	if boss.has_signal("hp_changed"):
		boss.hp_changed.connect(_on_boss_hp_changed)
	# Hiển thị giá trị ban đầu
	if boss is Monster:
		var display: String = boss.config.display_name \
			if boss.config and "display_name" in boss.config else str(boss.name)
		_name_label.text = display
		_update_bar(boss.hp, boss.max_hp)

func _build_ui() -> void:
	var viewport_size: Vector2 = get_tree().get_root().get_visible_rect().size
	var screen_w: float = float(viewport_size.x)
	var bar_w: int = int(screen_w * BAR_SCREEN_RATIO)

	# ── Panel gốc, anchor center-top ─────────────────────────────
	var panel := PanelContainer.new()
	panel.set_anchor(SIDE_LEFT,   0.5)
	panel.set_anchor(SIDE_RIGHT,  0.5)
	panel.set_anchor(SIDE_TOP,    0.0)
	panel.set_anchor(SIDE_BOTTOM, 0.0)
	panel.offset_left   = -bar_w / 2.0 - 14
	panel.offset_right  =  bar_w / 2.0 + 14
	panel.offset_top    =  MARGIN_TOP
	panel.offset_bottom =  MARGIN_TOP + BAR_HEIGHT + 52

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.08, 0.82)
	style.set_corner_radius_all(10)
	style.content_margin_left   = 10
	style.content_margin_right  = 10
	style.content_margin_top    = 6
	style.content_margin_bottom = 6
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)

	# ── Name label ────────────────────────────────────────────────
	_name_label = Label.new()
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.add_theme_font_size_override("font_size", 20)
	_name_label.add_theme_color_override("font_color", Color.WHITE)
	_name_label.add_theme_constant_override("outline_size", 3)
	_name_label.add_theme_color_override("font_outline_color", Color.BLACK)
	vbox.add_child(_name_label)

	# ── Bar stack: bg + fill + hp label ──────────────────────────
	var bar_root := Control.new()
	bar_root.custom_minimum_size = Vector2(bar_w, BAR_HEIGHT)
	vbox.add_child(bar_root)

	var bar_bg := ColorRect.new()
	bar_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bar_bg.color = Color(0.15, 0.15, 0.15, 1.0)
	bar_root.add_child(bar_bg)

	_bar_fill = ColorRect.new()
	_bar_fill.set_anchor(SIDE_LEFT,   0.0)
	_bar_fill.set_anchor(SIDE_TOP,    0.0)
	_bar_fill.set_anchor(SIDE_RIGHT,  1.0)   # sẽ bị thu hẹp khi HP giảm
	_bar_fill.set_anchor(SIDE_BOTTOM, 1.0)
	_bar_fill.color = Color(0.2, 1.0, 0.2, 1.0)
	bar_root.add_child(_bar_fill)

	# ── HP label — font size ~= bar height để cao bằng thanh bar ─
	_hp_label = Label.new()
	_hp_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Offset top âm để đẩy text lên chính giữa thanh bar (bù font descender)
	_hp_label.offset_top = -2.0
	_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hp_label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_hp_label.add_theme_font_size_override("font_size", int(BAR_HEIGHT) - 4)
	_hp_label.add_theme_color_override("font_color", Color.WHITE)
	_hp_label.add_theme_constant_override("outline_size", 4)
	_hp_label.add_theme_color_override("font_outline_color", Color.BLACK)
	bar_root.add_child(_hp_label)

func _update_bar(current: int, max_val: int) -> void:
	var ratio := float(current) / float(max_val) if max_val > 0 else 0.0
	_bar_fill.set_anchor(SIDE_RIGHT, maxf(ratio, 0.005))

	if   ratio > 0.5:  _bar_fill.color = Color(0.2, 1.0, 0.2)
	elif ratio > 0.25: _bar_fill.color = Color(1.0, 0.8, 0.0)
	else:              _bar_fill.color = Color(1.0, 0.2, 0.2)

	_hp_label.text = "%d / %d" % [current, max_val]

func _on_boss_hp_changed(current: int, max_val: int) -> void:
	_update_bar(current, max_val)
