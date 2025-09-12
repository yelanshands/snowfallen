extends RayCast3D

@export var speed := 50.0
@onready var remote_transform := RemoteTransform3D.new()
var damage_amount := 25.0

func _physics_process(delta: float) -> void:
	position -= global_basis * Vector3.BACK * speed * delta
	target_position = -(Vector3.BACK * speed * delta)
	force_raycast_update()
	var collided = get_collider()
	var current = collided
	if is_colliding():
		global_position = get_collision_point()
		set_physics_process(false)
		print(collided.name)
		if collided.name == "head":
			damage_amount = 100
		elif collided.name == "body":
			damage_amount = 25
		elif collided.name == "leg":
			damage_amount = 20
		while current:
			if current.is_in_group("attackable"):
				if current.has_method("apply_damage"):
					current.apply_damage(damage_amount)
					collided = current
				break
			current = current.get_parent()
		collided.add_child(remote_transform)
		remote_transform.global_transform = global_transform
		remote_transform.remote_path = remote_transform.get_path_to(self)
		remote_transform.tree_exited.connect(cleanup)
		
func cleanup() -> void:
	queue_free()
