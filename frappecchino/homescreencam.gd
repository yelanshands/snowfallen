extends TextureRect

@export var cam_sens: float = 0.005
var offset: Vector2
var default_pos: Vector2
var mouse_pos: Vector2

func _ready() -> void:
	default_pos = global_position

func _process(_delta: float) -> void:
	mouse_pos = get_global_mouse_position()
	offset = mouse_pos - default_pos
	global_position = lerp(global_position, (default_pos - offset).clamp(Vector2(-828, -623), Vector2(0, 0)), cam_sens)
