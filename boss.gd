# boss.gd
# Dùng CHUNG script với Monster.
# Chỉ cần gán BossConfig .tres vào @export var config.
# Boss tự động scale HP theo hp_multiplier.
# ───────────────────────────────────────────────────────────────────
# CÁCH TẠO BOSS MỚI:
#   1. Tạo file .tres BossConfig trong res://configs/
#   2. Set display_name, max_hp, hp_multiplier, skills
#   3. Gán vào @export var config trong Inspector
# ───────────────────────────────────────────────────────────────────
extends Monster

func _ready():
	if config != null and config is BossConfig:
		config.max_hp = int(config.max_hp * config.hp_multiplier)

	super._ready()

	if config != null and config.idle_animation != "":
		if anim_player != null and anim_player.has_animation(config.idle_animation):
			anim_player.play(config.idle_animation)
