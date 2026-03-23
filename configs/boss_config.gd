# boss_config.gd
# Kế thừa MonsterConfig, thêm thuộc tính riêng của Boss.
extends MonsterConfig
class_name BossConfig

## Lượng HP bonus so với Monster thường (nhân lên)
## VD: hp_multiplier = 5 → Boss có HP = Monster max_hp * 5
@export var hp_multiplier: float = 5.0
