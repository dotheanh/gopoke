# skill_data.gd
extends Resource
class_name SkillData

@export var skill_name: String
@export_enum("circle", "line", "cone") var shape: String = "circle"
@export var size: Vector3 = Vector3(1, 0.1, 1)

@export var damage: int = 10
@export var effect_range: float = 5.0

@export var cast_time: float = 1.0   # thời gian tụ lực
@export var cooldown: float = 3.0 
@export var speed: float = 1.0    # tốc độ đạn
