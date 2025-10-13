extends Node3D

@onready var camera: Camera3D = $SpringArm3D/PlayerCamera
@onready var player: CharacterBody3D = get_parent()

var default_recoil := 0.5
var current_recoil := default_recoil
var steady_recoil := default_recoil/2
#var recoil_speed := 40.0
var recoil_offset := 0.0

func _process(_delta: float) -> void:
	if recoil_offset > 0.001:
		recoil_offset = lerp(recoil_offset, 0.0, 0.05) * (1.0 - rotation_degrees.x/15.0)
		rotation_degrees.x = rotation_degrees.x + recoil_offset
	rotation_degrees.x = clamp(rotation_degrees.x, 0.0, 15.0)

func apply_recoil():
	current_recoil = steady_recoil if Input.is_action_pressed("crouch") else default_recoil
	recoil_offset += current_recoil + randf_range(-0.1, 0.1)
	
func return_to_origin():
	rotation.x = lerp(rotation.x, 0.0, 0.25)
