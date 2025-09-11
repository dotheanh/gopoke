# boss.gd
extends Monster
class_name Boss

func _ready():
	super._ready()
	anim_player.play("Animation")
	
func die():
	print("Boss defeated! Trigger cutscene...")
	super.die()  # gọi hàm die() của Monster
