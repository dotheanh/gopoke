extends Node
class_name GameManager

# Tham chiếu Player
@export var player: Node3D = null

func _ready():
	print("GameManager ready. Player:", player)


func on_player_died():
	show_game_over_ui()

func show_game_over_ui():
	# --- CanvasLayer để UI luôn hiển thị trên màn hình ---
	var canvas = CanvasLayer.new()
	canvas.name = "GameOverCanvas"
	get_tree().current_scene.add_child(canvas)

	# --- Background bán trong suốt (optional) ---
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.5)
	bg.anchor_left = 0
	bg.anchor_top = 0
	bg.anchor_right = 1
	bg.anchor_bottom = 1
	canvas.add_child(bg)

	# --- Label "Game Over" ---
	var label = Label.new()
	label.text = "GAME OVER"
	label.add_theme_font_size_override("font_size", 48)
	label.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VerticalAlignment.VERTICAL_ALIGNMENT_CENTER
	label.anchor_left = 0.25
	label.anchor_right = 0.75
	label.anchor_top = 0.3
	label.anchor_bottom = 0.5
	canvas.add_child(label)

	# --- Button Restart ---
	var btn = Button.new()
	btn.text = "Restart"
	btn.anchor_left = 0.4
	btn.anchor_right = 0.6
	btn.anchor_top = 0.55
	btn.anchor_bottom = 0.65
	canvas.add_child(btn)

	# --- Kết nối signal nhấn nút với hàm restart ---
	btn.pressed.connect(self.restart_game)

	# --- Tạm dừng game nếu muốn ---
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
