extends Node

@export var tween_intensity: float = 1.07
@export var tween_duration: float = 0.2
@export var settings_data: SettingsData

@onready var quit: TextureButton = $Control/MarginContainer/VBoxContainer/HBoxContainer/quitButton
@onready var crosshairs: CanvasLayer = $Crosshair
@onready var crosshair_margin: MarginContainer = $Crosshair/MarginContainer
@onready var hitcrosshair_cont: Control = $Crosshair/HitContainer
@onready var click: AudioStreamPlayer = $Click
@onready var fade_animation = $CanvasLayer/AnimationPlayer
@onready var mouse_sens_label: Label = $Control/MarginContainer/VBoxContainer/MouseSens/HBoxContainer2/Value
@onready var mouse_sens_slider: HSlider = $Control/MarginContainer/VBoxContainer/MouseSens/HBoxContainer/MouseSensSlider
#@onready var camera: Camera3D = $Background/SubViewportContainer/SubViewport/Camera3D

var rot_x = 0
var rot_y = 0
var cam_sens = 0.005
var hitting: bool = false
#var logged_x = 0.0
#var logged_y = 0.0
#var target_rot_x = 0.0
#var target_rot_y = 0.0
	
signal settingsclosed
	
func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	mouse_sens_slider.value = globals.settings_data.mouse_sens

func _process(_delta) -> void:
	if crosshairs.visible == true and Input.is_action_just_pressed("ui_cancel"):
		exit()
		
	if self.visible:
		crosshairs.visible = true
	else:
		crosshairs.visible = false
	
	crosshairs.transform.origin = crosshairs.transform.origin.lerp(get_viewport().get_mouse_position() - crosshair_margin.size/2.0, 0.3)
	
	buttonHovered(quit)
	
	if hitting:
		hitcrosshair_cont.scale = Vector2(lerp(hitcrosshair_cont.scale.x, 0.8, 0.4), lerp(hitcrosshair_cont.scale.y, 0.8, 0.4))
		
	if hitcrosshair_cont.scale.x > 0.77:
		hitcrosshair_cont.scale = Vector2(0.0, 0.0)
		hitting = false

func exit() -> void:
	emit_signal("settingsclosed")
	self.visible = false
	crosshairs.visible = false
	get_tree().paused = false

func do_tween(object: Object, property: String, value: Variant, duration: float):
	var tween = create_tween()
	tween.tween_property(object, property, value, duration)

func buttonHovered(button: TextureButton):
	if button.is_hovered():
		do_tween(button, "scale", Vector2.ONE * tween_intensity, tween_duration)
	else:
		do_tween(button, "scale", Vector2.ONE, tween_duration)

func _on_quit_button_pressed():
	exit()
	
func _on_mouse_sens_slider_value_changed(value: float) -> void:
	mouse_sens_label.text = str(mouse_sens_slider.value)
	globals.settings_data.mouse_sens = mouse_sens_slider.value
