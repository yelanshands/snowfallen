extends CharacterBody3D

@onready var spring_arm: SpringArm3D = $SpringArmPivot/SpringArm3D
@onready var camera: Camera3D = $SpringArmPivot/SpringArm3D/PlayerCamera
@onready var big_crosshair_cont: CanvasLayer = $Crosshair
@onready var crosshair_cont: MarginContainer = $Crosshair/MarginContainer
@onready var crosshair: TextureRect = $Crosshair/MarginContainer/Crosshair
@onready var hitcrosshair_cont: Control = $Crosshair/HitContainer
@onready var hitcrosshair: TextureRect = $Crosshair/HitContainer/HitCrosshair
@onready var audio: AudioStreamPlayer3D = $SpringArmPivot/SpringArm3D/PlayerCamera/Audio
@onready var score_label: Label = $CanvasLayer/MarginContainer/ScoreContainer/Score
@onready var animation: AnimationPlayer = $frappie/AnimationPlayer
@onready var hitbox: CollisionShape3D = $CollisionShape3D
@onready var skeleton: Skeleton3D = $frappie.get_node("Node/Armature/Skeleton3D")
@onready var fade_animation = $CanvasLayer/AnimationPlayer
@onready var green: ColorRect = $CanvasLayer/Health/Green
@onready var red: ColorRect = $CanvasLayer/Health/Red
@onready var hp_timer: Timer = $CanvasLayer/Health/Timer
@onready var settings: Node = $Settings
@onready var buttons: VBoxContainer = $CanvasLayer/MarginContainer/ScoreContainer/hbox/Buttons
@onready var play_again_button: TextureButton = $CanvasLayer/MarginContainer/ScoreContainer/hbox/Buttons/playAgainButton
@onready var settings_button: TextureButton = $CanvasLayer/MarginContainer/ScoreContainer/hbox/Buttons/settingsButton
@onready var quit_button: TextureButton = $CanvasLayer/MarginContainer/ScoreContainer/hbox/Buttons/quitButton
@onready var crosshairs: CanvasLayer = $CrosshairMenu
@onready var crosshair_margin: MarginContainer = $CrosshairMenu/MarginContainer
@onready var hitmenu_cont: Control = $CrosshairMenu/HitContainer
@onready var click: AudioStreamPlayer = $Click
@onready var deadbg_animation: AnimationPlayer = $CanvasLayer/deadbg/AnimationPlayer
@onready var score_animation: AnimationPlayer = $CanvasLayer/MarginContainer/ScoreContainer/Score/AnimationPlayer
@onready var players: HBoxContainer = $CanvasLayer/MarginContainer/ScoreContainer/hbox/Leaderboard/vbox/bottom/Players
@onready var leaderboard: ColorRect = $CanvasLayer/MarginContainer/ScoreContainer/hbox/Leaderboard
@onready var leaderboard_animation: AnimationPlayer = $CanvasLayer/MarginContainer/ScoreContainer/hbox/Leaderboard/AnimationPlayer

@export var friction: float = 0.25
@export var slide_accel: float = 100.0
@export var floor_snap: float = 10.0
@export var sprint_length: float = 15.0
@export var bullet_speed: float= 1400.0

const footstep_stream = preload("res://assets/audio/concrete-footsteps-6752.mp3")
const landing_stream = preload("res://assets/audio/land2-43790.mp3")
const jump_up = preload("res://assets/audio/jump-up.mp3")

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")*9.8
var default_cam_sens_value: float = 0.0025
var default_cam_sens: float = default_cam_sens_value
var cam_sens: float = default_cam_sens
var default_speed = 40.0  
var speed = default_speed
var jump_speed = 40.0
var sprint_mult = 1.5
var crouch_mult = 0.60
var shooting_mult = 0.85
var lerp_value = 8.0
var crosshair_size = 48.0
var crosshair_sprint = 32.0
var crosshair_crouch = 128.0
var crosshair_shooting = 80.0
var target_cam_roty = 0.0
var player_rot = 0.0
var in_air = false
var walking = false
var score: int = 0
var prev_floor_normal: Vector3 = Vector3.ZERO
var initial_sprint_boost: Vector3 = Vector3.ZERO
var sprint_boost: Vector3
var input_enabled: bool = true
var first_slide: bool = true
var slope_dir: Vector3
var slope_normal: Vector3 = Vector3(0, cos(atan(150.0 / 700.0)), sin(atan(150.0 / 700.0)))
var death_transform: float
var on_slope: bool
var default_font_size := 48
var in_game: bool = false
var button_pressed: bool = false
var clicking: bool = false

var head_bone: Node
var upper_torso: Node

signal on_ground
signal clickfinished

var max_hp := 300.0
var hp := max_hp
var hp_taken := 0.0
var high_scores: Array

var fov: float = 75.0
var aim_assist: bool = true
var target_aim: Vector3
var target_enemy = null
var target_dir: Vector3

func _init():
	floor_stop_on_slope = false
	floor_snap_length = floor_snap
	
func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	head_bone = skeleton.get_node("mixamorigHeadTop_End")
	upper_torso = skeleton.get_node("uppertorso/body")
	score_label.add_theme_font_size_override("font_size", default_font_size)
	update_leaderboard()
	high_scores = globals.settings_data.high_scores
	default_cam_sens = default_cam_sens_value * globals.settings_data.mouse_sens
	fov = globals.settings_data.fov
	
func _input(event):
	if not buttons.visible:
		if event.is_action_pressed("ui_cancel"):
			if not get_tree().paused:
				Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
				get_tree().paused = true
				settings.visible = true
				await settings.settingsclosed
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		if event.is_action_pressed("left_click"):
			if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
				get_viewport().set_input_as_handled()

func _process(_delta):
	default_cam_sens = default_cam_sens_value * settings.mouse_sens_slider.value
	fov = settings.fov_slider.value
	
	var camera_zrot = camera.global_rotation.z
	if animation.current_animation == "runslide":
		camera.global_rotation.z = lerp(camera_zrot, clamp(-head_bone.global_rotation.z, -0.2, 0.05), 0.05)
	else:
		camera.global_rotation.z = lerp(camera_zrot, 0.0, 0.05)
		
	if not hp_timer.is_stopped():
		red.size.y = lerp(red.size.y, (hp_taken/max_hp) * green.position.y, 0.2) + (1 if hp <= 0 else 0)
	else:
		hp_taken = 0.0
		green.size.y = lerp(green.size.y, (((hp+hp_taken)/max_hp) * green.position.y)-1, 0.2)
		red.size.y = lerp(red.size.y, 0.0, 0.2)
	red.position.y = green.position.y - green.size.y - 1
	
	if clicking:
		hitmenu_cont.scale = Vector2(lerp(hitmenu_cont.scale.x, 0.8, 0.8), lerp(hitmenu_cont.scale.y, 0.8, 0.8))
	
	if hitmenu_cont.scale.x >= 0.79:
		hitmenu_cont.scale = Vector2(0.0, 0.0)
		clicking = false
		emit_signal("clickfinished")

func _physics_process(delta: float) -> void:
	var current_vel = velocity
	var input = Input.get_vector("strafe_left", "strafe_right", "move_forward", "move_back")
	var movement_dir = (transform.basis * Vector3(input.x, 0, input.y)).normalized()
	var on_floor: bool = is_on_floor()
	var slide_vector: Vector3 = slope_dir * slide_accel
	on_slope = prev_floor_normal.y >= slope_normal.y - 0.0001 and prev_floor_normal.y <= slope_normal.y + 0.0001 and prev_floor_normal.z >= slope_normal.z - 0.0001 and prev_floor_normal.z <= slope_normal.z + 0.0001
	
	if hp <= 0:
		input_enabled = false
		camera.fov = lerp(camera.fov, fov * 1.25, 0.1)
		if in_game:
			score_label.add_theme_font_size_override("font_size", lerp(score_label.get_theme_font_size("font_size"), int(default_font_size*2.5), 0.8))
		if animation.assigned_animation != "dying":
			if settings.visible:
				settings.exit()
			velocity = Vector3.ZERO
			audio.stop()
			if not on_floor:
				await on_ground
			animation.stop()
			change_collision(false)
			animation.speed_scale = 2.75
			animation.play_section("dying", 0.22, 4.4, 0.5)
			if in_game:
				score_animation.play("fade_in")
		elif animation.current_animation_position >= 0.6 and animation.speed_scale != 1.0:
			animation.speed_scale = 1.0
		elif ((animation.current_animation_position >= 3.4 or Input.is_action_just_pressed("left_click")) and (fade_animation.assigned_animation != "buttons_fade_in" and fade_animation.assigned_animation != "fade_out")):
			if in_game:
				score_label.text = "\nyou died .\n" + str(score)
				for entry_index in range(high_scores.size()):
					if score > high_scores[entry_index][1]:
						var player_name = "frappie"
						globals.settings_data.high_scores.insert(entry_index, [player_name, score])
						globals.settings_data.high_scores.pop_back()
						update_leaderboard()
						break
				big_crosshair_cont.visible = false
				buttons.visible = true
				crosshairs.visible = true
				leaderboard.visible = true
				fade_animation.play("buttons_fade_in")
				leaderboard_animation.play("fade_in")
				Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
			else:
				fade_animation.play("fade_out")
		elif (animation.current_animation_position >= 2.4 or buttons.visible) and not deadbg_animation.assigned_animation:
			deadbg_animation.play("darken")
		if crosshairs.visible:
			crosshairs.transform.origin = crosshairs.transform.origin.lerp(get_viewport().get_mouse_position() - crosshair_margin.size/2.0, 0.3)
			
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
		elif Input.is_action_pressed("left_click"):
			cam_sens = default_cam_sens * crouch_mult * ((crouch_mult*crouch_mult) if aim_assist else 1.0)
			camera.fov = lerp(camera.fov, fov * shooting_mult, 0.15)
			crosshair.set_size(Vector2(lerp(crosshair.size.x, crosshair_shooting, 0.15), lerp(crosshair.size.y, crosshair_shooting, 0.15)))
		elif animation.current_animation != "runslide":
			cam_sens = default_cam_sens
			speed = default_speed
			camera.fov = lerp(camera.fov, fov, 0.05)
			crosshair.set_size(Vector2(lerp(crosshair.size.x, crosshair_size, 0.15), lerp(crosshair.size.y, crosshair_size, 0.15)))
		
		crosshair.position = Vector2(crosshair_cont.size.x/2.0-(crosshair.size.x/2.0), crosshair_cont.size.y/2.0-(crosshair.size.y/2.0))
		
		if aim_assist:
			if Input.is_action_pressed("left_click"):
				if not target_enemy:
					var space_state = get_world_3d().direct_space_state
					var query = PhysicsRayQueryParameters3D.create(camera.global_position, camera.global_position + camera.global_transform.basis.z * -1 * 1000.0, (1 << 11))
					var result = space_state.intersect_ray(query)
				
					if result:
						var collider = result.collider
						if collider.name == "aimassist":
							target_enemy = collider.get_owner()
							target_dir = (target_enemy.global_position - camera.global_position).normalized()
				else:
					var target_pos = target_enemy.global_position
					target_pos.y = rotation.y
					look_at(target_pos)
					rotate_y(deg_to_rad(180))
					#spring_arm.rotation.y += lerp(spring_arm.rotation.y, atan2(target_dir.x, target_dir.z), 0.7)
			else:
				target_cam_roty = 0.0
				target_enemy = null
			
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
		hitbox.shape.height = hitbox_height
		hitbox.position.y = hitbox_height/2

	elif hp > 0 and animation.assigned_animation != "dying":
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
	
	if on_slope and hp > 0:
		velocity.x += slide_vector.x
		velocity.z += slide_vector.z
			
	if input_enabled and Input.is_action_pressed("jump") and on_floor:
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
	if crosshairs.visible:
		cam_sens = default_cam_sens/5
	if event is InputEventMouseMotion:
		if input_enabled or (in_game and in_air):
			rotation.y -= event.relative.x * cam_sens
		elif hp <= 0:
			death_transform -= event.relative.x * cam_sens
			spring_arm.rotation.y = lerp(spring_arm.rotation.y, death_transform, 0.2)
		spring_arm.rotation.x -= event.relative.y * cam_sens
		spring_arm.rotation.x = clamp(spring_arm.rotation.x, -PI/4, PI/3) 

func apply_damage(damage_amount):
	if damage_amount > hp:
		damage_amount = hp
	if hp_timer.is_stopped():
		hp_taken = 0.0
		hp_timer.start(1.0)
	hp_taken += damage_amount
	hp -= damage_amount

func update_score(amount: int):
	if amount == 0:
		score = 0
	else:
		score += amount
	if hp > 0:
		score_label.text = "\n" + ("" if in_game else "   ")+ str(score)
	elif in_game:
		score_label.text = "\nyou died .\n" + str(score)
	
func change_collision(enabled: bool) -> void:
	for child in skeleton.get_children():
		for grandchild in child.get_children():
			if not grandchild is StaticBody3D:
				break
			else:
				for greatgrandchild in grandchild.get_children():
					if greatgrandchild is CollisionShape3D:
						greatgrandchild.disabled = not enabled
						
func update_leaderboard() -> void:
	for entry_index in range(high_scores.size()):
		players.get_node("Names/" + str(entry_index + 1)).text = high_scores[entry_index][0]
		players.get_node("Scores/" + str(entry_index + 1)).text = str(high_scores[entry_index][1])
						
func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.name == "glass" and animation.current_animation == "runslide" and animation.current_animation_position >= 0.1 and animation.current_animation_position <= 0.4:
		body.free()
		get_parent().animation.play_backwards("slide_in")
		audio.stop()
		fade_and_change_scene("res://game.tscn")
		
func fade_and_change_scene(scene_path: String):
	fade_animation.play("fade_out")
	await fade_animation.animation_finished
	get_tree().change_scene_to_file(scene_path)

func _on_play_again_button_pressed() -> void:
	play_again_button.disabled = true
	clicking = true
	click.play()
	fade_animation.play("fade_out")
	await fade_animation.animation_finished
	get_tree().reload_current_scene()

func _on_settings_button_pressed() -> void:
	clicking = true
	click.play()
	await clickfinished
	get_tree().paused = true
	settings.visible = true
	crosshairs.visible = false
	await settings.settingsclosed
	crosshairs.visible = true

func _on_quit_button_pressed() -> void:
	quit_button.disabled = true
	clicking = true
	click.play()
	if not button_pressed:
		button_pressed = true
		fade_and_change_scene("res://home.tscn")
