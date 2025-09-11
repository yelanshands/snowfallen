extends Node3D

const bullet = preload("res://bullet.tscn")
@onready var timer : Timer = $Timer
@onready var camera_end : Node3D = get_parent().get_node("SpringArmPivot/PlayerCamera/Line")
@onready var camera : Camera3D = get_parent().get_node("SpringArmPivot/PlayerCamera")
@onready var sound: AudioStreamPlayer3D = $AudioStreamPlayer3D

var cam_sens := 0.0025
var pewpew_roty := 0.0
var pewpew_rotx := 0.0

func _physics_process(_delta: float) -> void:
	if timer.is_stopped():
		if Input.is_action_pressed("left_click"):
			timer.start(0.1)
			var attack = bullet.instantiate()
			camera.add_child(attack)
			attack.position = camera.global_position
			attack.rotation = camera.global_rotation	
			if sound.is_playing():
				sound.stop()
			sound.play()

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		pewpew_rotx += event.relative.y * cam_sens
		rotation.x = pewpew_rotx - rotation.angle_to(camera_end.position)
