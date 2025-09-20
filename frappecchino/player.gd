extends CharacterBody3D

@onready var camera: Camera3D = $SpringArmPivot/PlayerCamera
@onready var spring_arm: SpringArm3D = $SpringArmPivot/SpringArm3D
@onready var spring_pos: Node3D = $SpringArmPivot/SpringArm3D/SpringPosition
@onready var crosshair_cont: MarginContainer = $/root/Game/CanvasLayer/MarginContainer
@onready var crosshair: TextureRect = crosshair_cont.get_child(0)
@onready var audio: AudioStreamPlayer3D = $Audio
@export var fov: float = 75.0
@export var friction: float = 0.25
@export var cam_sens: float = 0.0025
@export var slide_accel: float = 10.0
@export var max_slope_angle: float = deg_to_rad(15.0)
@export var floor_snap: float = 2.5

const footstep_stream = preload("res://assets/audio/concrete-footsteps-6752.mp3")
const landing_stream = preload("res://assets/audio/land2-43790.mp3")
const jump_up = preload("res://assets/audio/jump-up.mp3")

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
var in_air = false
var walking = false
var floor_normal: Vector3
var slope_angle: float

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	set_floor_snap_length(floor_snap)
	set_floor_stop_on_slope_enabled(false)
	safe_margin = 0.3
	floor_block_on_wall = true
	
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

func _physics_process(delta):
	if not is_on_floor():
		in_air = true
	if in_air and is_on_floor():
		in_air = false
		audio.stream = landing_stream
		audio.play()
		
	if ((velocity.x > 0.1 or velocity.x < -0.1) or (velocity.y > 0.1 or velocity.y < -0.1)) and is_on_floor() and not walking:
		if not audio.is_playing():
			walking = true
			audio.stream = footstep_stream
			audio.play()
	if (not (velocity.x > 0.1 or velocity.x < -0.1) or (velocity.y > 0.1 or velocity.y < -0.1)) and walking:
		audio.stop()
		walking = false
	
	var slope_dir: Vector3
	var input = Input.get_vector("strafe_left", "strafe_right", "move_forward", "move_back")
	var movement_dir = (transform.basis * Vector3(input.x, 0, input.y)).normalized()
	
	if not is_on_floor():
		velocity.y += -gravity * delta
	else:
		floor_normal = get_floor_normal()
		slope_angle = acos(floor_normal.dot(Vector3.UP))
		if rad_to_deg(slope_angle) > max_slope_angle:
			slope_dir = (Vector3.DOWN - floor_normal * Vector3.DOWN.dot(floor_normal)).normalized()
			velocity += slope_dir * slide_accel
		else:
			velocity.y = 0.0
			
	if Input.is_action_pressed("sprint"):
		speed = default_speed * sprint_mult
		camera.fov = lerp(camera.fov, fov * sprint_mult, 0.2)
		crosshair.set_size(Vector2(lerp(crosshair.size.x, crosshair_sprint, 0.3), lerp(crosshair.size.y, crosshair_sprint, 0.3)))
	elif Input.is_action_pressed("crouch"):
		speed = default_speed * crouch_mult
		camera.fov = lerp(camera.fov, fov * crouch_mult, 0.2)
		crosshair.set_size(Vector2(lerp(crosshair.size.x, crosshair_crouch, 0.3), lerp(crosshair.size.y, crosshair_crouch, 0.3)))
	else:
		speed = default_speed
		camera.fov = lerp(camera.fov, fov, 0.2)
		crosshair.set_size(Vector2(lerp(crosshair.size.x, crosshair_size, 0.3), lerp(crosshair.size.y, crosshair_size, 0.3)))
	
	if Input.is_action_pressed("jump") and is_on_floor():
		velocity.y = jump_speed
		audio.stop()
		walking = false
		audio.stream = jump_up
		audio.play()
	
	crosshair.position.x = crosshair_cont.size.x/2.0-(crosshair.size.x/2.0)
	crosshair.position.y = crosshair_cont.size.y/2.0-(crosshair.size.y/2.0)
	
	if not input:
		if is_on_floor():
			velocity.x = lerp(velocity.x, 0.0, friction)
			velocity.z = lerp(velocity.z, 0.0, friction)
	else:
		if is_on_floor():
			movement_dir = (movement_dir - floor_normal * movement_dir.dot(floor_normal)).normalized()
			var slope_factor = 1.0 - (slope_angle / deg_to_rad(max_slope_angle))
			var slope_speed = speed * clamp(slope_factor, 0.2, 1.0)
	
			velocity.x = -movement_dir.x * slope_speed
			velocity.z = -movement_dir.z * slope_speed
		else:
			velocity.x = -movement_dir.x * speed
			velocity.z = -movement_dir.z * speed
	#print(velocity)
	move_and_slide()
	
func _unhandled_input(event):
	if event is InputEventMouseMotion:
		rotation.y -= event.relative.x * cam_sens
		
		camera.rotation.x -= event.relative.y * cam_sens
		camera.rotation.x = clamp(camera.rotation.x, -PI/4, PI/2) 
		
	if event.is_action_pressed("wheel_up"):
		spring_arm.spring_length -= 1
	if event.is_action_pressed("wheel_down"):
		spring_arm.spring_length += 1
	spring_arm.spring_length = clamp(spring_arm.spring_length, 10, 45)
