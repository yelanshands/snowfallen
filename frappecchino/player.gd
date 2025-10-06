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
@onready var fade_animation = $CanvasLayer/AnimationPlayer
@onready var fade_rect = $CanvasLayer/ColorRect
@onready var tutorial: Node3D = get_parent()

@export var fov: float = 75.0
@export var friction: float = 0.25
@export var default_cam_sens: float = 0.0025
@export var slide_accel: float = 100.0
@export var floor_snap: float = 10.0
@export var sprint_length = 15.0

const footstep_stream = preload("res://assets/audio/concrete-footsteps-6752.mp3")
const landing_stream = preload("res://assets/audio/land2-43790.mp3")
const jump_up = preload("res://assets/audio/jump-up.mp3")

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")*9.8
var cam_sens: float = default_cam_sens
var default_speed = 40.0  
var speed = default_speed
var jump_speed = 40.0
var sprint_mult = 1.5
var crouch_mult = 0.60
var shooting_mult = 0.85
var lerp_value = 8.0
var crosshair_size = 48.0
var crosshair_sprint = 28.0
var crosshair_crouch = 128.0
var crosshair_shooting = 80.0
var target_cam_rotx = 0.0
var target_cam_roty = 0.0
var player_rot = 0.0
var in_air = false
var walking = false
var score: int = 0
var prev_floor_normal: Vector3 = Vector3.ZERO
var head_bone: Node
var initial_sprint_boost: Vector3 = Vector3.ZERO
var sprint_boost: Vector3
var input_enabled: bool = true
var first_slide: bool = true
var slope_dir: Vector3
var slope_normal: Vector3 = Vector3(0, cos(atan(150.0 / 700.0)), sin(atan(150.0 / 700.0)))

func _ready():
	captureMouse()
	floor_stop_on_slope = false
	floor_snap_length = floor_snap
	head_bone = skeleton.get_node("mixamorigHeadTop_End")
	
func captureMouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
func _input(event):
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if event.is_action_pressed("left_click"):
		if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			get_viewport().set_input_as_handled()

func _process(_delta):
	var camera_zrot = camera.global_rotation.z
	spring_pos.global_position = head_bone.global_position
	if animation.current_animation == "runslide":
		camera.global_rotation.z = lerp(camera_zrot, clamp(-head_bone.global_rotation.z, -0.2, 0.05), 0.05)
	else:
		camera.global_rotation.z = lerp(camera_zrot, 0.0, 0.05)

func _physics_process(delta: float) -> void:
	var current_vel = velocity
	var input = Input.get_vector("strafe_left", "strafe_right", "move_forward", "move_back")
	var movement_dir = (transform.basis * Vector3(input.x, 0, input.y)).normalized()
	var on_floor: bool = is_on_floor()
	var slide_vector: Vector3 = slope_dir * slide_accel
	var on_slope: bool = prev_floor_normal.y >= slope_normal.y - 0.0001 and prev_floor_normal.y <= slope_normal.y + 0.0001 and prev_floor_normal.z >= slope_normal.z - 0.0001 and prev_floor_normal.z <= slope_normal.z + 0.0001
	
	if not on_floor:
		in_air = true
	else:
		prev_floor_normal = get_floor_normal()
		slope_dir = (Vector3.DOWN - prev_floor_normal * Vector3.DOWN.dot(prev_floor_normal)).normalized()
	if in_air and on_floor:
		in_air = false
		audio.stream = landing_stream
		audio.play()

	if input_enabled:
		if on_slope:
			if ((abs(current_vel.x) > 0.1) or (abs(current_vel.y) > 0.1)):
				if current_vel.z < 0:
					if animation.assigned_animation == "jumpup" and not animation.current_animation:
						animation.play("riflecrouchruntostop", 0.5)
				if on_floor:
					if current_vel.z < 0 and animation.current_animation != "runslide":
						animation.play("riflecrouchrun", 0.5)
					if animation.current_animation != "runslide" and not audio.is_playing() and animation.current_animation:
						audio.stream = footstep_stream
						audio.play()
						
			if (abs(current_vel.x) <= 0.1) or (abs(current_vel.y) > 0.1):
				if current_vel.z >= 0:
					if not animation.current_animation and not on_floor and animation.assigned_animation == "jumpup":
						animation.play("riflecrouchruntostop", 0.5)
					elif animation.assigned_animation != "runslide" and animation.assigned_animation != "riflecrouchruntostop" or (animation.assigned_animation == "riflecrouchruntostop" and animation.current_animation_position == 0):
						animation.play("riflecrouchruntostop", 0.5)
				if audio.is_playing() and audio.stream == footstep_stream and (not animation.current_animation or (animation.current_animation == "riflecrouchruntostop" and animation.current_animation_position >= 1.00 and animation.current_animation_position <= 1.01)):
					audio.stop()
						
			if animation.assigned_animation == "runslide" and not animation.current_animation:
				animation.play("riflecrouchruntostop", 0.15)
				
		else:		
			if ((abs(current_vel.x) > 0.1) or (abs(current_vel.z) > 0.1)):
				if not animation.current_animation:
					if animation.assigned_animation == "riflecrouchruntostop" or animation.assigned_animation == "riflecrouchrun":
						animation.play("riflecrouchrun", 0.5)
					elif animation.assigned_animation == "runslide":
						animation.play("riflecrouchrun", 0.15)
				if animation.current_animation != "runslide" and not audio.is_playing():
					audio.stream = footstep_stream
					audio.play()
					
			if animation.current_animation == "riflecrouchrun" or (animation.assigned_animation == "runslide" and not animation.current_animation):
				if (abs(current_vel.x) > 0.1) or (abs(current_vel.z) > 0.1):
					animation.play("riflecrouchrun", 0.5)
				else:
					animation.play("riflecrouchruntostop", 0.15)
			elif animation.assigned_animation != "runslide" and animation.assigned_animation != "riflecrouchruntostop":
				animation.play("riflecrouchruntostop", 0.5)
			if audio.is_playing() and audio.stream == footstep_stream and (not animation.current_animation or (animation.current_animation == "riflecrouchruntostop" and animation.current_animation_position >= 1.00 and animation.current_animation_position <= 1.01)):
				audio.stop()
		
		if animation.current_animation == "runslide":
			camera.fov = lerp(camera.fov, fov * sprint_mult, 0.1)
			crosshair.set_size(Vector2(lerp(crosshair.size.x, crosshair_sprint, 0.15), lerp(crosshair.size.y, crosshair_sprint, 0.15)))
		if Input.is_action_pressed("crouch"):
			cam_sens = default_cam_sens * crouch_mult * crouch_mult
			speed = default_speed * crouch_mult
			camera.fov = lerp(camera.fov, fov * crouch_mult, 0.15)
			crosshair.set_size(Vector2(lerp(crosshair.size.x, crosshair_crouch, 0.1), lerp(crosshair.size.y, crosshair_crouch, 0.1)))
		elif animation.current_animation != "runslide":
			cam_sens = default_cam_sens
			speed = default_speed
			camera.fov = lerp(camera.fov, fov, 0.05)
			crosshair.set_size(Vector2(lerp(crosshair.size.x, crosshair_size, 0.15), lerp(crosshair.size.y, crosshair_size, 0.15)))
			
		if Input.is_action_pressed("left_click"):
			camera.fov = lerp(camera.fov, fov * shooting_mult, 0.15)
			crosshair.set_size(Vector2(lerp(crosshair.size.x, crosshair_shooting, 0.15), lerp(crosshair.size.y, crosshair_shooting, 0.15)))
		
		crosshair.position.x = crosshair_cont.size.x/2.0-(crosshair.size.x/2.0)
		crosshair.position.y = crosshair_cont.size.y/2.0-(crosshair.size.y/2.0)
		
		var lerp_vel = lerp(velocity, Vector3.ZERO, friction)
		
		if (not on_slope and (not input or animation.current_animation == "runslide")):
			velocity.x = lerp_vel.x
			velocity.z = lerp_vel.z
		else:
			velocity.x = -movement_dir.x * speed
			velocity.z = -movement_dir.z * speed
			
		if Input.is_action_just_pressed("sprint") and animation.current_animation != "runslide":
			initial_sprint_boost = Vector3.ZERO
			animation.play_section("runslide", 0, 1.1)
			sprint_boost = global_transform.basis.z.normalized() * sprint_length 
				
		if animation.current_animation == "runslide":
			initial_sprint_boost = lerp(initial_sprint_boost, sprint_boost, 0.3)
			velocity += initial_sprint_boost
			
		var hitbox_height = (head_bone.global_position.y - global_position.y) + 1
		$CollisionShape3D.shape.height = hitbox_height
		$CollisionShape3D.position.y = hitbox_height/2
	else:
		if first_slide:
			animation.play_section("runslide", 0, 1.1)
			sprint_boost = global_transform.basis.z.normalized() * 2
			first_slide = false
				
		if animation.current_animation == "runslide":
			initial_sprint_boost = lerp(initial_sprint_boost, sprint_boost, 0.3)
			velocity += initial_sprint_boost
		elif animation.current_animation != "riflecrouchruntostop":
			animation.play("riflecrouchruntostop", 0.15)
		
	if not on_floor:
		velocity.y -= gravity * delta * (1 if input_enabled else 2)
	elif not on_slope:
		velocity.y = 0.0
	
	if on_slope:
		velocity.x += slide_vector.x
		velocity.z += slide_vector.z
			
	if Input.is_action_pressed("jump") and on_floor:
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

func update_score(amount: int):
	if amount == 0:
		score = 0
	else:
		score += amount
	score_label.text = "\n   " + str(score)

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.name == "glass" and animation.current_animation == "runslide" and animation.current_animation_position >= 0.1 and animation.current_animation_position <= 0.4:
		body.free()
		tutorial.animation.play_backwards("slide_in")
		update_score(0)
		fade_and_change_scene("res://game.tscn")
		
func fade_and_change_scene(scene_path: String):
	fade_animation.play("fade_out")
	await fade_animation.animation_finished
	get_tree().change_scene_to_file(scene_path)
