extends RayCast3D

var speed := 100.0
var collided := false

func _physics_process(delta: float) -> void:
	position -= global_basis * Vector3.FORWARD * speed * delta
	target_position = -(Vector3.FORWARD * speed * delta)
	force_raycast_update()
	if is_colliding():
		global_position = get_collision_point()
		collided = true
		set_physics_process(false)
