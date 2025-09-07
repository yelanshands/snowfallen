extends CanvasLayer

@export var tween_intensity: float
@export var tween_duration: float

@onready var play: TextureButton = $Control/MarginContainer/VBoxContainer/playButton
@onready var settings: TextureButton = $Control/MarginContainer/VBoxContainer/settingsButton
@onready var quit: TextureButton = $Control/MarginContainer/VBoxContainer/quitButton

func _process(_delta):
	buttonHovered(play)
	buttonHovered(settings)
	buttonHovered(quit)

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
