extends SpringArm3D

var shake_strength := 0.05
var shake_decay := 8.0
var shake_offset := Vector3.ZERO

func _process(delta):
	shake_offset = shake_offset.lerp(Vector3.ZERO, shake_decay * delta)
	transform.origin = shake_offset

func apply_shake():
	shake_offset = Vector3(
		randf_range(-shake_strength, shake_strength),
		randf_range(-shake_strength, shake_strength),
		randf_range(-shake_strength * 0.5, shake_strength * 0.5)
	)
