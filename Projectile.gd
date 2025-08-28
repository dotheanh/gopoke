extends Area3D
class_name Projectile

@export var speed: float = 10.0
@export var damage: int = 30
var target_pos: Vector3

func _physics_process(delta):
	var dir = (target_pos - global_transform.origin)
	var distance = dir.length()
	if distance < 0.1:
		hit_target()
		return
	dir = dir.normalized()
	global_translate(dir * speed * delta)

func hit_target():
	 #Kiểm tra va chạm với Player
	var player = GameManagerGlobal.player
	if player and global_transform.origin.distance_to(player.global_transform.origin) < 1.0:
		if player.has_method("take_damage"):
			player.take_damage(damage)
			print("Player hit by Meteor for", damage, "HP")
	queue_free()
