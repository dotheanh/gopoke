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
	# Tính scaled_hp từ config, KHÔNG ghi vào resource gốc
	if config != null and config is BossConfig:
		var scaled_hp: int = int(config.max_hp * config.hp_multiplier)
		max_hp = scaled_hp
		hp = scaled_hp
		_hp_overridden = true  # Đánh dấu để monster._apply_config() không ghi đè

	super._ready()

	if config != null and config.idle_animation != "":
		if anim_player != null and anim_player.has_animation(config.idle_animation):
			anim_player.play(config.idle_animation)

	# Connect signal với BossHPBar sau khi BossHPBar đã init
	var boss_hp_bar = get_node_or_null("BossHPBar")
	if boss_hp_bar != null and boss_hp_bar.has_method("update_bar_from_outside"):
		hp_changed.connect(boss_hp_bar.update_bar_from_outside)
