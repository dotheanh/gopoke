# boss.gd
extends Monster
class_name Boss

@export var anim_player: AnimationPlayer

func _ready():
	anim_player.play("Animation")
	super._ready()
	
func die():
	print("Boss defeated! Trigger cutscene...")
	super.die()  # gọi hàm die() của Monster
