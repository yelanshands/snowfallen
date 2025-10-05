extends Node3D

@onready var camera: Camera3D = $SpringArm3D/PlayerCamera
@onready var player: CharacterBody3D = get_parent()

var default_recoil := 2.0
var current_recoil := default_recoil
var steady_recoil := 1.0
var recoil_speed := 40.0
var recoil_offset := 0.0

func _process(delta):
	if recoil_offset > 0.001:
		recoil_offset = lerp(recoil_offset, 0.0, recoil_speed * delta)
		rotation_degrees.x = rotation_degrees.x + recoil_offset
	rotation_degrees.x = clamp(rotation_degrees.x, 0.0, 15.0)

func apply_recoil():
	if camera.fov < 60: 
		current_recoil = steady_recoil
	else:
		current_recoil = default_recoil
	recoil_offset += current_recoil + randf_range(-0.3, 0.3)
	
func return_to_origin():
	rotation.x = lerp(rotation.x, 0.0, 0.25)	
