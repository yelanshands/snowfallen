extends Node3D

const bullet = preload("res://enemy_bullet.tscn")
@onready var timer : Timer = $Timer
@onready var enemy: CharacterBody3D = get_parent()
@onready var phantom: StaticBody3D = enemy.get_node("enemi/Node/Skeleton3D/pewpew/phantom")
@onready var phantom_mesh: MeshInstance3D = phantom.get_node("MeshInstance3D")

@export var fire_rate: float = 1.0/11.0

var firing: bool = false
var phantom_mat: StandardMaterial3D
var accuracy: float
var target: String
var target_node: Node
var speed: float = 1400.0

func _ready() -> void:
	phantom_mat = phantom_mesh.mesh.surface_get_material(0).duplicate()
	phantom_mesh.set_surface_override_material(0, phantom_mat)
	accuracy = enemy.accuracy
	target = enemy.target
	
func _process(_delta: float) -> void:
	if enemy.animation.current_animation == "FiringRifle0" and enemy.animation.current_animation_position <= 0.5:
		phantom_mat.albedo_color.v = lerp(phantom_mat.albedo_color.v, 10.0, 0.8)
	else:
		phantom_mat.albedo_color.v = lerp(phantom_mat.albedo_color.v, 0.0, 0.6)
		
	if enemy.animation.assigned_animation == "FiringRifle0" and not enemy.animation.current_animation:
		enemy.animation.play("IdleAiming0", 0.5)

func fire() -> void:
	if timer.is_stopped():
		timer.start(fire_rate)
		enemy.animation.play("FiringRifle0", 0.5)
		phantom_mat.albedo_color.v = 0.0
		var attack = bullet.instantiate()
		attack.speed = speed
		phantom.add_child(attack)
		attack.global_position = phantom.global_position
		var spread = Vector3(
			randf_range(-accuracy, accuracy),
			randf_range(-accuracy, accuracy),
			randf_range(-accuracy, accuracy)
		)
		if target == "head":
			target_node = enemy.player.head_bone
		elif target == "uppertorso":
			target_node = enemy.player.upper_torso
		attack.global_rotation = phantom.global_transform.looking_at(target_node.global_position, Vector3.UP).basis.get_euler() + spread
