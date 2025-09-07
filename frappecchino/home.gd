extends CanvasLayer

@export var tween_intensity: float
@export var tween_duration: float

@onready var play: TextureButton = $Control/MarginContainer/VBoxContainer/playButton
@onready var settings: TextureButton = $Control/MarginContainer/VBoxContainer/settingsButton
@onready var quit: TextureButton = $Control/MarginContainer/VBoxContainer/quitButton
@onready var camera: Camera3D = $Background/SubViewportContainer/SubViewport/Camera3D

var rot_x = 0
var rot_y = 0
var LOOKAROUND_SPEED = 0.005
var logged_x = 0.0
var logged_y = 0.0
var target_rot_x = 0.0
var target_rot_y = 0.0
	
func _process(_delta):
	buttonHovered(play)
	buttonHovered(settings)
	buttonHovered(quit)
	
	var current_x = get_viewport().get_mouse_position()[0]
	var current_y = get_viewport().get_mouse_position()[1]
	
	# Compute the difference between the target mouse position and the current rotation
	target_rot_x += (current_x - logged_x) * LOOKAROUND_SPEED
	target_rot_y += (current_y - logged_y) * LOOKAROUND_SPEED
	
	if target_rot_x < 0.6:
		target_rot_x = 0.6
	elif target_rot_x > 1.2: 
		target_rot_x = 1.2
	if target_rot_y < -0.4:
		target_rot_y = -0.4
	elif target_rot_y > 0.4:
		target_rot_y = 0.4

	# Interpolate the current rotation towards the target rotation smoothly
	rot_x = lerp_angle(rot_x, target_rot_x, 0.005)
	rot_y = lerp_angle(rot_y, target_rot_y, 0.005)
	print("x:" + str(rot_x) + "    y: " + str(rot_y))
	
	logged_x = current_x
	logged_y = current_y

	camera.transform.basis = Basis() # reset rotation
	camera.rotate_object_local(Vector3(0, -1, 0), rot_x) # first rotate in Y
	camera.rotate_object_local(Vector3(-1, 0, 0), rot_y) # then rotate in X
		
#
#
#func _input(event):
	#if event is InputEventMouseMotion:
		#
		# modify accumulated mouse rotation
		#rot_x += event.screen_relative.x * LOOKAROUND_SPEED
		#rot_y += event.screen_relative.y * LOOKAROUND_SPEED
		#print("x:" + str(rot_x) + "    y: " + str(rot_y))
		#camera.transform.basis = Basis() # reset rotation
		#camera.rotate_object_local(Vector3(0, -1, 0), rot_x) # first rotate in Y
		#camera.rotate_object_local(Vector3(-1, 0, 0), rot_y) # then rotate in X
#func _input(event):
	#if event is InputEventMouseMotion:
		## 'event.relative' provides the change in mouse position since the last frame.
		#print("Mouse moved by: ", event.relative) 
		## 'event.position' provides the current absolute mouse position on the screen.
		#print("Mouse position: ", event.position)

func do_tween(object: Object, property: String, value: Variant, duration: float):
	var tween = create_tween()
	tween.tween_property(object, property, value, duration)

func buttonHovered(button: TextureButton):
	if button.is_hovered():
		do_tween(button, "scale", Vector2.ONE * tween_intensity, tween_duration)
	else:
		do_tween(button, "scale", Vector2.ONE, tween_duration)

func _on_quit_button_pressed():
	get_tree().quit()
