extends Node3D

const bullet = preload("res://bullet.tscn")
@onready var timer : Timer = $Timer
@onready var player: CharacterBody3D = get_parent()
@onready var camera_end : Node3D = player.get_node("SpringArmPivot/SpringArm3D/PlayerCamera/Line")
@onready var camera : Camera3D = player.get_node("SpringArmPivot/SpringArm3D/PlayerCamera")
@onready var sound: AudioStreamPlayer3D = player.get_node("SpringArmPivot/SpringArm3D/PlayerCamera/PewpewAudio")
@onready var pivot = player.get_node("SpringArmPivot")
@onready var arm = pivot.get_node("SpringArm3D")
@onready var phantom: MeshInstance3D = player.get_node("frappie/Node/Armature/Skeleton3D/pewpew/phantom")
@onready var phantom_mat: StandardMaterial3D = (phantom.get_node("MeshInstance3D").mesh.surface_get_material(0) as StandardMaterial3D)

@export var fire_rate: float = 1.0/11.0
@export var recoil_strength: float = 20.0

var cam_sens := 0.0025
var pewpew_roty := 0.0
var pewpew_rotx := 0.0
var phantom_origin: Vector3
var firing: bool = false

func _ready() -> void:
	phantom_origin = phantom.rotation_degrees

func _process(_delta: float) -> void:
	if firing:
		phantom.rotation_degrees.x = lerp(phantom.rotation_degrees.x, phantom_origin.x - recoil_strength, 0.25)
		phantom_mat.albedo_color.v = lerp(phantom_mat.albedo_color.v, 10.0, 0.6)
	else:
		phantom.rotation_degrees.x = lerp(phantom.rotation_degrees.x, phantom_origin.x, 0.25)
		phantom_mat.albedo_color.v = lerp(phantom_mat.albedo_color.v, 0.0, 0.6)
		
func _physics_process(_delta: float) -> void:
	if Input.is_action_pressed("left_click"):
		if timer.is_stopped():
			timer.start(fire_rate)
			phantom_mat.albedo_color.v = 0.0
			firing = true
			pivot.apply_recoil()
			arm.apply_shake()
			var attack = bullet.instantiate()
			camera.add_child(attack)
			attack.global_position = camera.global_position
			attack.global_rotation = camera.global_rotation
			if sound.is_playing():
				sound.stop()
			sound.play()
	else:
		pivot.return_to_origin()
		if phantom.rotation_degrees.x < phantom_origin.x - recoil_strength * 0.9:
			firing = false

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		rotation.x = -camera.rotation.x - rotation.angle_to(camera_end.position)
