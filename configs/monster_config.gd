extends Resource
class_name MonsterConfig

@export var display_name: String = "Monster"
@export var max_hp: int = 100
@export var delay_before_first_cast: float = 1.0
@export var rotation_speed: float = 5.0
@export var skills: Array[SkillData] = []
@export var idle_animation: String = "Idle"
@export var collision_radius: float = 0.5
@export var collision_height: float = 2.0
