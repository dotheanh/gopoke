extends CanvasLayer
class_name HUD

# Chỉ cần kéo thả trực tiếp từ editor
@export var hp_bar: ProgressBar

var player: Node = null

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

func _on_player_hp_changed(hp: int, max_hp: int) -> void:
	if hp_bar:
		hp_bar.max_value = max_hp
		hp_bar.value = hp
