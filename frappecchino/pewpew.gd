extends Node3D

const bullet = preload("res://bullet.tscn")
@onready var timer : Timer = $Timer
@onready var player: CharacterBody3D = get_parent()
@onready var camera_end : Node3D = player.get_node("SpringArmPivot/SpringArm3D/PlayerCamera/Line")
@onready var camera : Camera3D = player.get_node("SpringArmPivot/SpringArm3D/PlayerCamera")
@onready var sound: AudioStreamPlayer3D = player.get_node("SpringArmPivot/SpringArm3D/PlayerCamera/PewpewAudio")
@onready var pivot = player.get_node("SpringArmPivot")
@onready var arm = pivot.get_node("SpringArm3D")

@export var fire_rate: float = 1.0/11.0

var cam_sens := 0.0025
var pewpew_roty := 0.0
var pewpew_rotx := 0.0

func _physics_process(_delta: float) -> void:
	if Input.is_action_pressed("left_click"):
		if timer.is_stopped():
			timer.start(fire_rate)
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

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		rotation.x = -camera.rotation.x - rotation.angle_to(camera_end.position)
