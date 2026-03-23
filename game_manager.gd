extends Node
class_name GameManager

const HUD_SCENE := preload("res://ui/HUD.tscn")

# Tham chiếu Player
@export var player: Node3D = null
var hud: HUD = null

# Đếm số enemy còn sống
var _enemy_count: int = 0

func _ready():
	_ensure_hud()
	print("GameManager ready. Player:", player)

	# Đếm tất cả enemy trong scene sau 1 frame (chờ scene setup xong)
	await get_tree().process_frame
	_count_enemies()

func _count_enemies() -> void:
	var enemies := get_tree().get_nodes_in_group("Enemy")
	_enemy_count = enemies.size()
	for enemy in enemies:
		if enemy.has_signal("died") and not enemy.died.is_connected(_on_enemy_died):
			enemy.died.connect(_on_enemy_died)
	print("Total enemies:", _enemy_count)

func _on_enemy_died() -> void:
	_enemy_count -= 1
	print("Enemy died. Remaining:", _enemy_count)
	if _enemy_count <= 0:
		# Chờ chút để animation chết chạy xong
		await get_tree().create_timer(0.5).timeout
		show_victory_ui()

func _ensure_hud():
	if hud == null:
		print("HUD is null → creating")
		hud = HUD_SCENE.instantiate() as HUD
		print("After instantiate, hud = ", hud)
		get_tree().current_scene.add_child(hud)
		if player:
			print("Binding player: ", player)
			hud.bind_player(player)
	else:
		print("HUD already exists: ", hud)

func register_player(p: Node3D) -> void:
	player = p
	_ensure_hud()
	if hud:
		hud.bind_player(player)

func on_player_died():
	show_game_over_ui()

# ── Victory UI — tất cả quái đã chết ─────────────────────────────
func show_victory_ui():
	var canvas = CanvasLayer.new()
	canvas.name = "VictoryCanvas"
	get_tree().current_scene.add_child(canvas)

	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.5)
	bg.anchor_left = 0; bg.anchor_top = 0
	bg.anchor_right = 1; bg.anchor_bottom = 1
	canvas.add_child(bg)

	var label = Label.new()
	label.text = "VICTORY!"
	label.add_theme_font_size_override("font_size", 52)
	label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.anchor_left = 0.2; label.anchor_right = 0.8
	label.anchor_top = 0.3; label.anchor_bottom = 0.5
	canvas.add_child(label)

	var btn = Button.new()
	btn.text = "Replay"
	btn.anchor_left = 0.4; btn.anchor_right = 0.6
	btn.anchor_top = 0.55; btn.anchor_bottom = 0.65
	canvas.add_child(btn)
	btn.pressed.connect(self.restart_game)

	get_tree().paused = true

# ── Game Over UI — player chết ────────────────────────────────────
func show_game_over_ui():
	var canvas = CanvasLayer.new()
	canvas.name = "GameOverCanvas"
	get_tree().current_scene.add_child(canvas)

	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.5)
	bg.anchor_left = 0; bg.anchor_top = 0
	bg.anchor_right = 1; bg.anchor_bottom = 1
	canvas.add_child(bg)

	var label = Label.new()
	label.text = "GAME OVER"
	label.add_theme_font_size_override("font_size", 48)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.anchor_left = 0.25; label.anchor_right = 0.75
	label.anchor_top = 0.3; label.anchor_bottom = 0.5
	canvas.add_child(label)

	var btn = Button.new()
	btn.text = "Restart"
	btn.anchor_left = 0.4; btn.anchor_right = 0.6
	btn.anchor_top = 0.55; btn.anchor_bottom = 0.65
	canvas.add_child(btn)
	btn.pressed.connect(self.restart_game)

	get_tree().paused = true

func restart_game():
	print("restart_game")
	var current_scene = get_tree().current_scene
	var scene_path = current_scene.filename
	var new_scene = load(scene_path).instantiate()
	get_tree().current_scene.queue_free()
	get_tree().current_scene = new_scene
	get_tree().root.add_child(new_scene)
	get_tree().paused = false
