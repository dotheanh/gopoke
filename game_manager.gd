extends Node
class_name GameManager

# Tham chiếu Player
@export var player: Node3D = null

func _ready():
	print("GameManager ready. Player:", player)
