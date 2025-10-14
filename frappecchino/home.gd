extends Node

@export var tween_intensity: float
@export var tween_duration: float

@onready var play: TextureButton = $Control/MarginContainer/VBoxContainer/playButton
@onready var settings_button: TextureButton = $Control/MarginContainer/VBoxContainer/settingsButton
@onready var settings: CanvasLayer = $Settings
@onready var quit: TextureButton = $Control/MarginContainer/VBoxContainer/quitButton
@onready var crosshairs: CanvasLayer = $Crosshair
@onready var crosshair_margin: MarginContainer = $Crosshair/MarginContainer
@onready var hitcrosshair_cont: Control = $Crosshair/HitContainer
@onready var click: AudioStreamPlayer = $Click
@onready var fade_animation = $CanvasLayer/AnimationPlayer
#@onready var camera: Camera3D = $Background/SubViewportContainer/SubViewport/Camera3D

var rot_x = 0
var rot_y = 0
var cam_sens = 0.005
var hitting: bool = false
#var logged_x = 0.0
#var logged_y = 0.0
#var target_rot_x = 0.0
#var target_rot_y = 0.0

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
	play.disabled = false
	settings_button.disabled = false
	quit.disabled = false

func _process(_delta):
	crosshairs.transform.origin = crosshairs.transform.origin.lerp(get_viewport().get_mouse_position() - crosshair_margin.size/2.0, 0.3)
	
	buttonHovered(play)
	buttonHovered(settings_button)
	buttonHovered(quit)
	
	if hitting:
		hitcrosshair_cont.scale = Vector2(lerp(hitcrosshair_cont.scale.x, 0.8, 0.4), lerp(hitcrosshair_cont.scale.y, 0.8, 0.4))
		
	if hitcrosshair_cont.scale.x > 0.77:
		hitcrosshair_cont.scale = Vector2(0.0, 0.0)
		hitting = false
		
	#var current_x = get_viewport().get_mouse_position()[0]
	#var current_y = get_viewport().get_mouse_position()[1]
	
	#camera.global_position.x = current_x
	#camera.global_position.y = current_y
	
	#target_rot_x += (current_x - logged_x) * cam_sens
	#target_rot_x = clamp(target_rot_x, 0.6, 1.2)
	#
	#target_rot_y += (current_y - logged_y) * cam_sens
	#target_rot_y = clamp(target_rot_y, -0.4, 0.4)
#
	#rot_x = lerp_angle(rot_x, target_rot_x, 0.005)
	#rot_y = lerp_angle(rot_y, target_rot_y, 0.005)
	##print("x:" + str(rot_x) + "    y: " + str(rot_y))
	#
	#logged_x = current_x
	#logged_y = current_y

	#camera.transform.basis = Basis() 
	#camera.rotate_object_local(Vector3(0, -1, 0), rot_x) 
	#camera.rotate_object_local(Vector3(-1, 0, 0), rot_y)

func do_tween(object: Object, property: String, value: Variant, duration: float):
	var tween = create_tween()
	tween.tween_property(object, property, value, duration)

func buttonHovered(button: TextureButton):
	if button.is_hovered():
		do_tween(button, "scale", Vector2.ONE * tween_intensity, tween_duration)
	else:
		do_tween(button, "scale", Vector2.ONE, tween_duration)

func _on_play_button_pressed():
	play.disabled = true
	hitting = true
	click.play()
	fade_animation.play("fade_out")
	await fade_animation.animation_finished
	get_tree().change_scene_to_file("res://intro.tscn")

func _on_quit_button_pressed():
	quit.disabled = true
	get_tree().quit()
	
func _on_settings_button_pressed() -> void:
	settings_button.disabled = true
	if not get_tree().paused:
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		get_tree().paused = true
		settings.visible = true
	await settings.settingsclosed
	settings_button.disabled = false
