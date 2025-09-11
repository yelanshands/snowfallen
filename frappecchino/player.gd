extends CharacterBody3D

@onready var camera: Camera3D = $SpringArmPivot/PlayerCamera
@onready var spring_arm: SpringArm3D = $SpringArmPivot/SpringArm3D
@onready var spring_pos: Node3D = $SpringArmPivot/SpringArm3D/SpringPosition
@onready var crosshair_cont: MarginContainer = $/root/Game/CanvasLayer/MarginContainer
@onready var crosshair: TextureRect = crosshair_cont.get_child(0)

@export var fov: float = 75.0
@export var friction: float = 0.25
@export var cam_sens := 0.0025

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")*9.8
var default_speed = 40.0  
var speed = default_speed
var jump_speed = 40.0
var sprint_mult = 1.25
var crouch_mult = 0.75
var lerp_value = 8.0
var crosshair_size = 60.0
var crosshair_sprint = 40.0
var crosshair_crouch = 80.0
var target_cam_rotx = 0.0
var target_cam_roty = 0.0
var player_rot = 0.0

func _init():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if event.is_action_pressed("left_click"):
		if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			get_viewport().set_input_as_handled()

func _process(_delta):
	camera.position.x = spring_pos.position.x
	camera.position.z = spring_pos.position.z
	camera.position.y = spring_pos.position.y - PI/4 - (camera.rotation.x + PI/4)*3

func get_input():
	var input = Input.get_vector("strafe_left", "strafe_right", "move_forward", "move_back")
	var movement_dir = transform.basis * Vector3(input.x, 0, input.y)
	
	if Input.is_action_pressed("sprint"):
		speed = lerp(speed, default_speed * sprint_mult, 0.4)
		camera.fov = lerp(camera.fov, fov * sprint_mult, 0.2)
		crosshair.set_size(Vector2(lerp(crosshair.size.x, crosshair_sprint, 0.3), lerp(crosshair.size.y, crosshair_sprint, 0.3)))
	elif Input.is_action_pressed("crouch"):
		speed = lerp(speed, default_speed * crouch_mult, 0.4)
		camera.fov = lerp(camera.fov, fov * crouch_mult, 0.2)
		crosshair.set_size(Vector2(lerp(crosshair.size.x, crosshair_crouch, 0.3), lerp(crosshair.size.y, crosshair_crouch, 0.3)))
	else:
		speed = lerp(speed, default_speed, 0.4)
		camera.fov = lerp(camera.fov, fov, 0.2)
		crosshair.set_size(Vector2(lerp(crosshair.size.x, crosshair_size, 0.3), lerp(crosshair.size.y, crosshair_size, 0.3)))
		
	if Input.is_action_pressed("jump") and is_on_floor():
		velocity.y = jump_speed
		
	crosshair.position.x = crosshair_cont.size.x/2.0-(crosshair.size.x/2.0)
	crosshair.position.y = crosshair_cont.size.y/2.0-(crosshair.size.y/2.0)
	
	if not Input.get_vector("strafe_left", "strafe_right", "move_forward", "move_back"):
		velocity.x = lerp(velocity.x, 0.0, friction)
		velocity.z = lerp(velocity.z, 0.0, friction)
	else:
		velocity.x = -movement_dir.x * speed
		velocity.z = -movement_dir.z * speed
	
func _physics_process(delta):
	velocity.y += -gravity * delta
	get_input()
	move_and_slide()
	
func _unhandled_input(event):
	if event is InputEventMouseMotion:
		player_rot -= event.relative.x * cam_sens
		rotation.y = player_rot - rotation.angle_to(camera.position)
		
		camera.rotation.x -= event.relative.y * cam_sens
		camera.rotation.x = clamp(camera.rotation.x, -PI/4, PI/2) 
		
	if event.is_action_pressed("wheel_up"):
		spring_arm.spring_length -= 1
	if event.is_action_pressed("wheel_down"):
		spring_arm.spring_length += 1
	spring_arm.spring_length = clamp(spring_arm.spring_length, 10, 45)
