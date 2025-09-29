extends CharacterBody3D

@onready var spring_arm: SpringArm3D = $SpringArmPivot/SpringArm3D
@onready var camera: Camera3D = $SpringArmPivot/SpringArm3D/PlayerCamera
@onready var spring_pos: Node3D = $SpringArmPivot/SpringArm3D/SpringPosition
@onready var crosshair_cont: MarginContainer = $CanvasLayer/MarginContainer
@onready var crosshair: TextureRect = crosshair_cont.get_node("Crosshair")
@onready var audio: AudioStreamPlayer3D = $SpringArmPivot/SpringArm3D/PlayerCamera/Audio
@onready var score_label: Label = $CanvasLayer/MarginContainer/ScoreContainer/Score
@onready var animation: AnimationPlayer = $frappie/AnimationPlayer
@onready var hitbox: CollisionShape3D = $CollisionShape3D
@onready var skeleton: Skeleton3D = $frappie.get_node("Node/Armature/Skeleton3D")

@export var fov: float = 75.0
@export var friction: float = 0.25
@export var default_cam_sens: float = 0.0025
@export var slide_accel: float = 10.0
@export var max_slope_angle: float = 0.2
@export var floor_snap: float = 2.5
@export var in_game: bool = true

const footstep_stream = preload("res://assets/audio/concrete-footsteps-6752.mp3")
const landing_stream = preload("res://assets/audio/land2-43790.mp3")
const jump_up = preload("res://assets/audio/jump-up.mp3")

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")*9.8
var cam_sens: float = default_cam_sens
var default_speed = 40.0  
var speed = default_speed
var jump_speed = 40.0
var sprint_length = 200.0
var sprint_mult = 1.5
var crouch_mult = 0.60
var lerp_value = 8.0
var crosshair_size = 60.0
var crosshair_sprint = 40.0
var crosshair_crouch = 100.0
var target_cam_rotx = 0.0
var target_cam_roty = 0.0
var player_rot = 0.0
var in_air = false
var walking = false
var floor_normal: Vector3
var slope_angle: float
var score: int = 0
var prev_floor_normal: Vector3 = Vector3.ZERO

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	floor_stop_on_slope = false
	floor_snap_length = floor_snap
	
func _input(event):
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if event.is_action_pressed("left_click"):
		if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			get_viewport().set_input_as_handled()

func _process(_delta):
	var head_bone = skeleton.get_node("mixamorigHeadTop_End")
	var camera_zrot = camera.global_rotation.z
	spring_pos.global_position = head_bone.global_position
	if animation.current_animation == "runslide":
		camera.global_rotation.z = lerp(camera_zrot, clamp(-head_bone.global_rotation.z, -0.2, 0.05), 0.05)
	else:
		camera.global_rotation.z = lerp(camera_zrot, 0.0, 0.05)

func _physics_process(delta):
	if not is_on_floor():
		in_air = true
	else:
		prev_floor_normal = get_floor_normal()
	if in_air and is_on_floor():
		in_air = false
		audio.stream = landing_stream
		audio.play()

	if prev_floor_normal != Vector3.UP:
		if ((velocity.x > 0.1 or velocity.x < -0.1) or (velocity.y > 0.1 or velocity.y < -0.1)):
			if velocity.z < 0:
				if animation.assigned_animation == "jumpup" and not animation.current_animation:
					animation.play("riflecrouchruntostop", 0.5)
			if is_on_floor():
				if velocity.z < 0 and animation.current_animation != "runslide":
					animation.play("riflecrouchrun", 0.5)
				if animation.current_animation != "runslide" and not audio.is_playing() and animation.current_animation:
					audio.stream = footstep_stream
					audio.play()
					
		if (not (velocity.x > 0.1 or velocity.x < -0.1) or (velocity.y > 0.1 or velocity.y < -0.1)):
			if velocity.z >= 0:
				if not animation.current_animation and not is_on_floor() and animation.assigned_animation == "jumpup":
					animation.play("riflecrouchruntostop", 0.5)
				elif animation.assigned_animation != "runslide" and animation.assigned_animation != "riflecrouchruntostop" or (animation.assigned_animation == "riflecrouchruntostop" and animation.current_animation_position == 0):
					animation.play("riflecrouchruntostop", 0.5)
			if audio.stream == footstep_stream and (animation.current_animation != "riflecrouchruntostop" or (animation.current_animation == "riflecrouchruntostop" and animation.current_animation_position >= 1.0)):
				audio.stop()
					
		if animation.assigned_animation == "runslide" and not animation.current_animation:
			animation.play("riflecrouchruntostop", 0.15)
			
	else:
		if ((velocity.x > 0.1 or velocity.x < -0.1) or (velocity.z > 0.1 or velocity.z < -0.1)):
			if not animation.current_animation:
				if animation.assigned_animation == "riflecrouchruntostop" or animation.assigned_animation == "riflecrouchrun":
					animation.play("riflecrouchrun", 0.5)
				elif animation.assigned_animation == "runslide":
					animation.play("riflecrouchrun", 0.15)
			if animation.current_animation != "runslide" and not audio.is_playing():
				audio.stream = footstep_stream
				audio.play()
					
		if (not (velocity.x > 0.1 or velocity.x < -0.1) or (velocity.z > 0.1 or velocity.z < -0.1)):
			if animation.current_animation == "riflecrouchrun" or (animation.assigned_animation == "runslide" and not animation.current_animation):
				animation.play("riflecrouchruntostop", 0.15)
			elif animation.assigned_animation != "runslide" and animation.assigned_animation != "riflecrouchruntostop":
				animation.play("riflecrouchruntostop", 0.5)
			if audio.stream == footstep_stream and (animation.current_animation != "riflecrouchruntostop" or (animation.current_animation == "riflecrouchruntostop" and animation.current_animation_position >= 1.0)):
				audio.stop()
				
	var slope_dir: Vector3
	var input = Input.get_vector("strafe_left", "strafe_right", "move_forward", "move_back")
	var movement_dir = (transform.basis * Vector3(input.x, 0, input.y)).normalized()
			
	if Input.is_action_just_pressed("sprint") and animation.current_animation != "runslide":
		animation.play_section("runslide", 0, 1.1)
		if is_on_floor():
			velocity += global_transform.basis.z.normalized() * sprint_length 
		else:
			velocity += global_transform.basis.z.normalized() * sprint_length/4 
	if animation.current_animation == "runslide":
		camera.fov = lerp(camera.fov, fov * sprint_mult, 0.1)
		crosshair.set_size(Vector2(lerp(crosshair.size.x, crosshair_sprint, 0.15), lerp(crosshair.size.y, crosshair_sprint, 0.15)))
	if Input.is_action_pressed("crouch"):
		cam_sens = default_cam_sens * crouch_mult * crouch_mult
		speed = default_speed * crouch_mult
		camera.fov = lerp(camera.fov, fov * crouch_mult, 0.15)
		crosshair.set_size(Vector2(lerp(crosshair.size.x, crosshair_crouch, 0.15), lerp(crosshair.size.y, crosshair_crouch, 0.15)))
	elif animation.current_animation != "runslide":
		cam_sens = default_cam_sens
		speed = default_speed
		camera.fov = lerp(camera.fov, fov, 0.05)
		crosshair.set_size(Vector2(lerp(crosshair.size.x, crosshair_size, 0.15), lerp(crosshair.size.y, crosshair_size, 0.15)))
	
	crosshair.position.x = crosshair_cont.size.x/2.0-(crosshair.size.x/2.0)
	crosshair.position.y = crosshair_cont.size.y/2.0-(crosshair.size.y/2.0)
	
	#print(animation.current_animation, "  ", animation.current_animation_position, "    ", prev_floor_normal)
	#print(velocity)
	
	if not is_on_floor():
		velocity.y += -gravity * delta
	else:
		floor_normal = get_floor_normal()
		slope_angle = acos(floor_normal.dot(Vector3.UP))
		slope_dir = (Vector3.DOWN - floor_normal * Vector3.DOWN.dot(floor_normal)).normalized()
		if slope_angle > max_slope_angle:
			velocity += slope_dir * slide_accel
		else:
			velocity.y = 0.0
	
	if not input:
		if is_on_floor():
			velocity.x = lerp(velocity.x, 0.0, friction)
			velocity.z = lerp(velocity.z, 0.0, friction)
	else:
		if is_on_floor():
			movement_dir = movement_dir - (slope_dir * friction)
		velocity.x = -movement_dir.x * speed
		velocity.z = -movement_dir.z * speed
			
	if Input.is_action_pressed("jump") and is_on_floor():
		if animation.assigned_animation == "riflecrouchruntostop" or animation.assigned_animation == "riflecrouchrun":
			velocity.y = jump_speed
			animation.play_section("jumpup", 0.1, 0.5333, 0.5)
			audio.stop()
			audio.stream = jump_up
			audio.play()
		elif animation.current_animation == "runslide":
			velocity.y = jump_speed

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
	#print(spring_arm.spring_length)

func update_score(amount: int):
	score += amount
	score_label.text = "\n   " + str(score)
