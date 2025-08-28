# boss.gd
extends Monster
class_name Boss

func die():
	print("Boss defeated! Trigger cutscene...")
	super.die()  # gọi hàm die() của Monster
