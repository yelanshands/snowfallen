extends SpringArm3D

@onready var pivot: Node3D = get_parent()
@onready var camera: Camera3D = $PlayerCamera

var shake_max := 3.0
var shake_strength := shake_max
var steady_recoil := shake_max/2
var shake_decay := 20.0
var shake_offset := Vector3.ZERO
var shake_target := Vector3.ZERO

func _process(delta):
	shake_offset = shake_offset.lerp(shake_target, 8.0 * delta)
	shake_target = shake_target.lerp(Vector3.ZERO, 0.25)
	transform.origin = shake_offset

func apply_shake():
	shake_strength = (pivot.rotation_degrees.x/15.0) * (steady_recoil if camera.fov < 70.0 else shake_max)
	shake_target = Vector3(
		randf_range(-shake_strength, shake_strength),
		randf_range(-shake_strength, shake_strength),
		randf_range(-shake_strength*0.5, shake_strength*0.5)
	)
